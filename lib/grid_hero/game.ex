defmodule GridHero.Game do
  @moduledoc """
  The game server is responsible for all state within a single game.

  It's also responsible for starting any player processes with `connect_player/2`.
  """

  # Don't restart the game server, as all state is lost anyway.
  # Instead, players should see an error message and create a new game themselves.
  use GenServer, restart: :temporary

  alias GridHero.GameList
  alias GridHero.GridMap
  alias GridHero.Player

  # How often the game ticks in milliseconds
  @tick_speed 100

  defstruct [:refs, :id, :map, :game_list, :shutdown_timer, players: MapSet.new()]

  @type state :: %{players: [Player.state()]}

  # Client

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    game_list = Keyword.get(opts, :game_list, GameList)

    GenServer.start_link(__MODULE__, {id, game_list})
  end

  @spec connect_player(pid(), String.t()) :: {:ok, pid()} | {:error, :no_user}
  def connect_player(game_pid, name) when is_pid(game_pid) and is_binary(name) do
    GenServer.call(game_pid, {:connect_player, name})
  end

  @spec game_state(pid()) :: state()
  def game_state(game_pid) when is_pid(game_pid) do
    GenServer.call(game_pid, :game_state)
  end

  @spec get_map(pid()) :: GridMap.t()
  def get_map(game_pid) when is_pid(game_pid) do
    GenServer.call(game_pid, :get_map)
  end

  @spec attack(pid(), pid(), GridMap.position()) :: :ok
  def attack(game_pid, player_pid, position) when is_pid(game_pid) and is_pid(player_pid) do
    GenServer.cast(game_pid, {:attack, player_pid, position})
  end

  # Server

  @impl true
  def init({id, game_list}) do
    shutdown_timer = Process.send_after(self(), :player_check, 10_000)
    Process.send_after(self(), :tick, @tick_speed)

    {:ok,
     %__MODULE__{
       refs: %{},
       id: id,
       map: GridMap.generate(),
       game_list: game_list,
       shutdown_timer: shutdown_timer
     }}
  end

  @impl true
  def handle_call({:connect_player, name}, _from, state) do
    position = GridMap.get_spawn_position(state.map)
    opts = [name: name, position: position, map: state.map, game: self()]

    case GridHero.PlayerSupervisor.start_child(opts) do
      {:ok, player_pid} ->
        if state.shutdown_timer != nil do
          Process.cancel_timer(state.shutdown_timer)
        end

        ref = Process.monitor(player_pid)

        state = %{
          state
          | refs: Map.put(state.refs, ref, player_pid),
            players: MapSet.put(state.players, player_pid),
            shutdown_timer: nil
        }

        GameList.increment_player_count(state.game_list, state.id)
        {:reply, {:ok, player_pid}, state}

      _ ->
        {:reply, {:error, :no_user}, state}
    end
  end

  @impl true
  def handle_call(:game_state, _from, state) do
    game_state = %{players: Enum.map(state.players, &Player.get_state/1)}

    {:reply, game_state, state}
  end

  @impl true
  def handle_call(:get_map, _from, state) do
    {:reply, state.map, state}
  end

  @impl true
  def handle_cast({:attack, player_pid, position}, state) do
    for player <- state.players, player != player_pid do
      Player.enemy_attack(player, position)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    game_state = %{players: Enum.map(state.players, &Player.get_state/1)}

    Phoenix.PubSub.broadcast(GridHero.PubSub, "game:#{state.id}", {:tick, game_state})
    Process.send_after(self(), :tick, @tick_speed)

    {:noreply, state}
  end

  @impl true
  def handle_info(:player_check, state) do
    # A game is started by a player which then connects to it.
    # If, after a few seconds, no player connects to the game,
    # then the game will end to avoid empty games.
    if state.refs == %{} do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    # Player disconnect.
    {pid, refs} = Map.pop(state.refs, ref)

    timer =
      if GameList.decrement_player_count(state.game_list, state.id) == 0 do
        # No more players, start shutdown counter.
        Process.send_after(self(), :player_check, 5000)
      else
        nil
      end

    state = %{
      state
      | refs: refs,
        players: MapSet.delete(state.players, pid),
        shutdown_timer: timer
    }

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

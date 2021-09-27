defmodule GridHero.Player do
  use GenServer, restart: :temporary

  alias GridHero.GridMap
  alias GridHero.Game

  defstruct [:name, :alive, :game, :game_ref, :position, :map]

  @typep t :: %__MODULE__{
           name: String.t(),
           alive: boolean(),
           game: pid(),
           game_ref: reference(),
           position: GridMap.position(),
           map: GridMap.t()
         }

  @type state :: %{name: String.t(), alive: boolean(), position: GridMap.position()}

  # Client

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    game_pid = Keyword.fetch!(opts, :game)
    name = Keyword.fetch!(opts, :name)
    position = Keyword.fetch!(opts, :position)
    map = Keyword.fetch!(opts, :map)

    GenServer.start_link(__MODULE__, {name, position, map, game_pid})
  end

  def get_state(player_pid) when is_pid(player_pid) do
    GenServer.call(player_pid, :get_state)
  end

  def move(player_pid, direction)
      when is_pid(player_pid) and direction in [:up, :down, :left, :right] do
    GenServer.call(player_pid, {:move, direction})
  end

  def attack(player_pid) do
    GenServer.cast(player_pid, :attack)
  end

  def enemy_attack(player_pid, position) do
    GenServer.cast(player_pid, {:enemy_attack, position})
  end

  # Server

  @impl true
  @spec init({String.t(), GridMap.position(), GridMap.t(), game :: pid}) ::
          {:ok, GridHero.Player.t()}
  def init({name, position, map, game}) when is_binary(name) and is_pid(game) do
    # I didn't link here because links are bidirectional, and I don't want a player
    # crashing to also take down the game.
    ref = Process.monitor(game)

    {:ok,
     %__MODULE__{
       name: name,
       alive: true,
       game: game,
       game_ref: ref,
       position: position,
       map: map
     }}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, %{name: state.name, alive: state.alive, position: state.position}, state}
  end

  @impl true
  def handle_call({:move, direction}, _from, state) do
    if state.alive do
      {x, y} = state.position

      new_position =
        case direction do
          :up -> {x, y - 1}
          :down -> {x, y + 1}
          :left -> {x - 1, y}
          :right -> {x + 1, y}
        end

      if GridMap.valid_move?(state.map, new_position) do
        {:reply, new_position, %{state | position: new_position}}
      else
        {:reply, state.position, state}
      end
    else
      {:reply, state.position, state}
    end
  end

  @impl true
  def handle_cast(:attack, state) do
    if state.alive do
      Game.attack(state.game, self(), state.position)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:enemy_attack, attack_position}, state) do
    if state.alive do
      dead? = was_hit?(state.position, attack_position)

      if dead? do
        Process.send_after(self(), :respawn, 5000)
      end

      {:noreply, %{state | alive: not dead?}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:respawn, state) do
    {:noreply, %{state | alive: true, position: GridMap.get_spawn_position(state.map)}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _, reason}, %{game_ref: ref}) do
    {:stop, reason}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp was_hit?(player_pos, {x, y}) do
    attack_cells =
      for hit_x <- [x - 1, x, x + 1],
          hit_y <- [y - 1, y, y + 1],
          do: {hit_x, hit_y}

    Enum.any?(attack_cells, &(&1 == player_pos))
  end
end

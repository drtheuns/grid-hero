defmodule GridHero.GameList do
  @moduledoc """
  The game list process handles record keeping of which games are currently
  active, and how many players they have.

  All games should be started with `create_game/2`.
  """
  use GenServer

  @type game_id :: String.t()

  # Alias for the typing, import for usage.
  # Record was used here instead of a struct to simplify working with ETS, as functions
  # such as update_counter/3 don't work with maps.
  import GridHero.GameList.Entry
  alias GridHero.GameList.Entry

  # Client

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, server, opts)
  end

  @spec all(atom()) :: list(Entry.t())
  def all(server \\ __MODULE__) do
    :ets.tab2list(server)
  end

  @spec get_game(atom(), game_id()) :: {:ok, Entry.t()} | :error
  def get_game(server \\ __MODULE__, game_id) when is_binary(game_id) do
    # Lookup happens in the calling process.
    case :ets.lookup(server, game_id) do
      [entry(id: ^game_id) = game] -> {:ok, game}
      _ -> :error
    end
  end

  @spec create_game(server :: pid() | atom(), String.t()) :: Entry.t()
  def create_game(server \\ __MODULE__, name) when is_binary(name) do
    GenServer.call(server, {:create_game, name})
  end

  @spec increment_player_count(server :: pid() | atom(), game_id()) :: non_neg_integer()
  def increment_player_count(server \\ __MODULE__, game_id) do
    GenServer.call(server, {:update_player_count, game_id, +1})
  end

  @spec decrement_player_count(server :: pid() | atom(), game_id()) :: non_neg_integer()
  def decrement_player_count(server \\ __MODULE__, game_id) do
    GenServer.call(server, {:update_player_count, game_id, -1})
  end

  # Server

  @impl true
  def init(server) do
    # The game list will be a concurrently readable ETS server, so it's quick to access
    # from any calling process. Writes will only be performed by this server.
    :ets.new(server, [
      :protected,
      :named_table,
      # Record in Elixir is 0-based, but 1-based is expected here.
      keypos: entry(:id) + 1,
      read_concurrency: true
    ])

    # Refs hold all the references to the monitored game processes.
    # When a game process exits, it's ejected from the game list.
    refs = %{}

    {:ok, {server, refs}}
  end

  @impl true
  def handle_call({:create_game, name}, _from, {server, refs}) do
    id = generate_id()

    {:ok, pid} = GridHero.GameSupervisor.start_child(id: id, game_list: server)
    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, id)
    entry = entry(id: id, name: name, pid: pid)

    :ets.insert(server, entry)

    {:reply, entry, {server, refs}}
  end

  @impl true
  def handle_call({:update_player_count, game_id, step}, _from, {server, refs}) do
    update_op =
      if step > 0 do
        {entry(:player_count) + 1, step}
      else
        # Ensure we cannot decrement lower than 0.
        {entry(:player_count) + 1, step, 0, 0}
      end

    new_player_count = :ets.update_counter(server, game_id, update_op)

    {:reply, new_player_count, {server, refs}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {server, refs}) do
    # Whenever a game exits, remove it from this game list.
    {id, refs} = Map.pop(refs, ref)

    if id != nil do
      :ets.delete(server, id)
    end

    {:noreply, {server, refs}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp generate_id() do
    id = Base.encode32(:crypto.strong_rand_bytes(15), padding: false)

    # Although the chance is low, avoid any ID collisions with existing games.
    case get_game(id) do
      {:ok, _} -> generate_id()
      _ -> id
    end
  end
end

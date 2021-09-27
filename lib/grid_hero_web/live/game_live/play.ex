defmodule GridHeroWeb.GameLive.Play do
  use GridHeroWeb, :live_view

  import GridHero.GameList.Entry

  alias GridHero.Game
  alias GridHero.GameList
  alias GridHero.GameList.Entry
  alias GridHero.Player
  alias Phoenix.LiveView.Socket

  @impl true
  def mount(%{"id" => game_id}, %{"name" => name}, socket) do
    case GameList.get_game(game_id) do
      {:ok, game} ->
        game_pid = entry(game, :pid)

        socket =
          socket
          |> assign(:name, name)
          |> assign(:map, Game.get_map(game_pid))
          |> connect_to_game(game, name)
          |> prepare_gamestate(Game.game_state(game_pid))

        {:ok, socket}

      _ ->
        socket =
          socket
          |> put_flash(:error, gettext("Game not found"))
          |> redirect(to: Routes.game_path(socket, :index))

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("keyup", %{"key" => "ArrowUp"}, socket), do: move_player(socket, :up)
  def handle_event("keyup", %{"key" => "ArrowDown"}, socket), do: move_player(socket, :down)
  def handle_event("keyup", %{"key" => "ArrowLeft"}, socket), do: move_player(socket, :left)
  def handle_event("keyup", %{"key" => "ArrowRight"}, socket), do: move_player(socket, :right)
  def handle_event("keyup", %{"key" => "a"}, socket), do: attack(socket)
  def handle_event("keyup", _, socket), do: {:noreply, socket}
  def handle_event("up", _, socket), do: move_player(socket, :up)
  def handle_event("down", _, socket), do: move_player(socket, :down)
  def handle_event("left", _, socket), do: move_player(socket, :left)
  def handle_event("right", _, socket), do: move_player(socket, :right)
  def handle_event("attack", _, socket), do: attack(socket)

  defp move_player(socket, direction) do
    Player.move(socket.assigns.player_state.pid, direction)

    {:noreply, socket}
  end

  defp attack(socket) do
    Player.attack(socket.assigns.player_state.pid)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, socket) do
    # The player process went down.
    # Future improvement could be to automatically reconnect to the game and respawn.
    socket =
      if ref == socket.assigns.player_state.ref do
        socket
        |> put_flash(:error, gettext("Lost connection to game"))
        |> redirect(to: Routes.game_path(socket, :index))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:tick, game_state}, socket) do
    {:noreply, prepare_gamestate(socket, game_state)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  @impl true
  def terminate(reason, socket) do
    # Also cleanup the player process.
    if Map.has_key?(socket.assigns, :player_state) do
      Process.exit(socket.assigns.player_state.pid, reason)
    end
  end

  @spec connect_to_game(Socket.t(), Entry.t(), String.t()) :: Socket.t()
  defp connect_to_game(socket, game, name) do
    if connected?(socket) and Map.has_key?(socket.assigns, :player_state) == false do
      entry(id: id, pid: game_pid) = game

      # PubSub.subscribe(GridHero.PubSub, "game:#{id}")

      # The assignment states that the player must be separate GenServer, which
      # is why I've done this. Otherwise, I'd probably have let this socket connection
      # act as the player process.
      case Game.connect_player(game_pid, name) do
        {:ok, pid} ->
          ref = Process.monitor(pid)

          Phoenix.PubSub.subscribe(GridHero.PubSub, "game:#{id}")

          assign(socket, :player_state, %{
            pid: pid,
            ref: ref,
            game_pid: game_pid
          })

        _ ->
          socket
          |> put_flash(:error, gettext("Failed to connect to server"))
          |> redirect(to: Routes.game_path(socket, :index))
      end
    else
      socket
    end
  end

  defp prepare_gamestate(socket, game_state) do
    map = socket.assigns.map

    players =
      game_state.players
      |> Enum.map(fn %{position: {x, y}} = player ->
        Map.put(
          player,
          :grid_pos,
          "top: calc(70vw / #{map.width} * #{y}); left: calc(70vw / #{map.width} * #{x});"
        )
      end)

    assign(socket, :players, players)
  end
end

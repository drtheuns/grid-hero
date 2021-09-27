defmodule GridHeroWeb.GameController do
  use GridHeroWeb, :controller
  alias GridHero.GameList
  import GridHero.GameList.Entry

  def index(conn, _params) do
    games =
      GridHero.GameList.all()
      # Make it a bit easier to work with in templates.
      |> Stream.map(fn game -> to_map(game) end)

    render(conn, "index.html", games: games, name: get_session(conn, :name))
  end

  def create(conn, %{"name" => name}) do
    name =
      case String.trim(name) do
        "" -> get_session(conn, :name)
        name -> name
      end

    # After the redirect, the player will be started and connect to the game.
    entry(id: id) = GameList.create_game(name)

    redirect(conn, to: Routes.game_play_path(conn, :play, id))
  end

  def create(conn, _) do
    conn
    |> put_flash(:error, gettext("Missing game name"))
    |> redirect(to: Routes.game_path(conn, :index))
  end
end

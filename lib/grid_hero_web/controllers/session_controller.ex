defmodule GridHeroWeb.SessionController do
  use GridHeroWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", error: nil)
  end

  def new_session(conn, params) do
    name =
      params
      |> Map.get("name", "")
      |> String.trim()

    case name do
      "" ->
        render(conn, "index.html", error: gettext("Name may not be empty"))

      _ ->
        # No protection against a name being already taken.
        path = params["next"] || Routes.game_path(conn, :index)

        conn
        |> Plug.Conn.put_session(:name, name)
        |> redirect(to: path)
    end
  end
end

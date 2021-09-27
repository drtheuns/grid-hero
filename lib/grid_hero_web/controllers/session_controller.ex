defmodule GridHeroWeb.SessionController do
  use GridHeroWeb, :controller

  def index(conn, params) do
    render(conn, "index.html", error: nil, next: Map.get(params, "next"))
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
        path = Map.get(params, "next", Routes.game_path(conn, :index))

        conn
        |> put_session(:name, name)
        |> redirect(to: path)
    end
  end
end

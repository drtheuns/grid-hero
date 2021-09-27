defmodule GridHeroWeb.Middleware.Session do
  import Phoenix.Controller, only: [redirect: 2]

  alias GridHeroWeb.Router.Helpers, as: Routes

  def requires_session(conn, _) do
    if has_session?(conn) do
      conn
    else
      redirect(conn, to: Routes.session_path(conn, :index, next: conn.request_path))
    end
  end

  def only_no_session(conn, _) do
    if has_session?(conn) do
      redirect(conn, to: Routes.game_path(conn, :index))
    else
      conn
    end
  end

  defp has_session?(conn) do
    Plug.Conn.get_session(conn, :name) != nil
  end
end

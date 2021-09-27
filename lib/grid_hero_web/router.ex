defmodule GridHeroWeb.Router do
  use GridHeroWeb, :router

  import GridHeroWeb.Middleware.Session

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GridHeroWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :session_required do
    plug :requires_session
  end

  pipeline :no_session do
    plug :only_no_session
  end

  scope "/", GridHeroWeb do
    pipe_through [:browser, :only_no_session]

    get "/", SessionController, :index
    post "/session/new", SessionController, :new_session
  end

  scope "/", GridHeroWeb do
    pipe_through [:browser, :session_required]

    get "/games", GameController, :index
    post "/games", GameController, :create
    live "/game/:id", GameLive.Play, :play
  end

  # Other scopes may use custom stacks.
  # scope "/api", GridHeroWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GridHeroWeb.Telemetry
    end
  end
end

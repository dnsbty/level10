defmodule Level10Web.Router do
  use Level10Web, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Level10Web.FetchUser
    plug :put_root_layout, {Level10Web.LayoutView, "root.html"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug Level10Web.AdminAuth
  end

  scope "/admin" do
    pipe_through [:browser, :admin]
    live_dashboard "/dashboard", metrics: Level10.Telemetry
  end

  scope "/", Level10Web do
    pipe_through :api

    get "/health", HealthController, :index
  end

  scope "/", Level10Web do
    pipe_through [:browser]

    live "/display", DisplayLive, :join
    live "/display/:join_code", DisplayLive, :observe

    live "/game/:join_code", GameLive, :play
    live "/scores/:join_code", ScoringLive, :display

    live "/create", LobbyLive, :create
    live "/join", LobbyLive, :join
    live "/join/:join_code", LobbyLive, :join
    live "/wait/:join_code", LobbyLive, :wait

    live "/", LobbyLive, :none
  end
end

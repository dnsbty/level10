defmodule Level10Web.Router do
  use Level10Web, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  pipeline :admins_only do
    plug :basic_auth, username: "admin", password: "dennisisthebest"
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {Level10Web.LayoutView, "root.html"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Level10Web do
    pipe_through :browser

    live "/", LobbyLive
    live "/game/:join_code", GameLive
    live "/scores/:join_code", ScoringLive
  end

  scope "/admin" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: Level10Web.Telemetry
  end
end

defmodule Level10Web.Router do
  use Level10Web, :router

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
  end

  # Other scopes may use custom stacks.
  # scope "/api", Level10Web do
  #   pipe_through :api
  # end
end

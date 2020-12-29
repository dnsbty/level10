defmodule Level10Web.Router do
  use Level10Web, :router

  import Level10Web.UserAuth
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
    plug :fetch_current_user
    plug :put_root_layout, {Level10Web.LayoutView, "root.html"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/admin" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: Level10.Telemetry
  end

  scope "/", Level10Web do
    pipe_through :api

    get "/health", HealthController, :index
  end

  ## Authentication routes

  scope "/", Level10Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", Level10Web do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm

    live "/display", DisplayLive
    live "/display/:join_code", DisplayLive

    live "/", LobbyLive
  end

  scope "/", Level10Web do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    live "/game/:join_code", GameLive
    live "/scores/:join_code", ScoringLive

    live "/:action", LobbyLive
    live "/:action/:join_code", LobbyLive
  end
end

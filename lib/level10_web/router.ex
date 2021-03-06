defmodule Level10Web.Router do
  use Level10Web, :router

  import Level10Web.UserAuth
  import Phoenix.LiveDashboard.Router

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
    pipe_through [:browser, :require_authenticated_user, :require_admin_role]
    live_dashboard "/dashboard", metrics: Level10.Telemetry, ecto_repos: [Level10.Repo]
  end

  if Application.get_env(:level10, :include_sent_email_route?, false) do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
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

    live "/display", DisplayLive, :join
    live "/display/:join_code", DisplayLive, :observe

    live "/", LobbyLive, :none
  end

  scope "/", Level10Web do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    live "/game/:join_code", GameLive, :play
    live "/scores/:join_code", ScoringLive, :display

    live "/create", LobbyLive, :create
    live "/join", LobbyLive, :join
    live "/join/:join_code", LobbyLive, :join
    live "/wait/:join_code", LobbyLive, :wait
  end
end

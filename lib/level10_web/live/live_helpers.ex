defmodule Level10Web.LiveHelpers do
  @moduledoc """
  These helpers can be called by various live views and provide functions that
  act similar to plugs. They can be used for verifying authenitcation.
  """

  import Phoenix.LiveView
  alias Level10.Accounts
  alias Level10Web.Router.Helpers, as: Routes

  @doc """
  Authenticates the user by looking into the session and fetching a user
  associated with the current session.
  """
  def fetch_current_user(socket, session) do
    user_token = session["user_token"]
    user = user_token && Accounts.get_user_by_session_token(user_token)
    assign(socket, :current_user, user)
  end

  @doc """
  Used for live views that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(socket) do
    if socket.assigns[:current_user] do
      socket
    else
      socket
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: Routes.user_session_path(socket, :new))
    end
  end
end

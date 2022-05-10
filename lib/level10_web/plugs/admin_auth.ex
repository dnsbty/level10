defmodule Level10Web.AdminAuth do
  @moduledoc """
  Provides HTTP Basic Auth configured at runtime.
  """

  @behaviour Plug

  @impl Plug
  def init(_opts), do: %{}

  @impl Plug
  def call(conn, _opts) do
    credentials = Application.get_env(:level10, :admin_credentials)
    Plug.BasicAuth.basic_auth(conn, credentials)
  end
end

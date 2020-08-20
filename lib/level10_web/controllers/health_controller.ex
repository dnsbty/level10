defmodule Level10Web.HealthController do
  use Level10Web, :controller

  def index(conn, _params) do
    json(conn, %{healthy: true})
  end
end

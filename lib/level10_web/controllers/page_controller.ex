defmodule Level10Web.PageController do
  @moduledoc false

  use Level10Web, :controller

  def privacy_policy(conn, _params) do
    render(conn, :privacy_policy)
  end
end

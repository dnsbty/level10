defmodule Level10Web.PageController do
  @moduledoc false

  use Level10Web, :controller

  def privacy_policy(conn, _params) do
    # text-violet-200
    # text-violet-100
    render(conn, "privacy_policy.html")
  end
end

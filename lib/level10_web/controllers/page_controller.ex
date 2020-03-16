defmodule Level10Web.PageController do
  use Level10Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

defmodule Level10Web.UserController do
  @moduledoc false

  use Level10Web, :controller
  alias Level10.Users

  def create(conn, _params) do
    user_id = Users.generate_uuid()
    token = Phoenix.Token.sign(conn, "user auth", user_id, max_age: :infinity)
    json(conn, %{id: user_id, token: token})
  end
end

defmodule Level10Web.PageController do
  @moduledoc false

  use Level10Web, :controller

  def privacy_policy(conn, _params) do
    render(conn, :privacy_policy)
  end

  def sms_terms(conn, _params) do
    render(conn, :sms_terms)
  end
end

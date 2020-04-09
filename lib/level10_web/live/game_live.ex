defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10.Games

  def mount(params, _session, socket) do
    assigns = [
      join_code: params["join_code"],
      player_id: params["player_id"]
    ]

    Games.subscribe(params["join_code"])

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~L"""
    <span>Hello</span>
    """
  end
end

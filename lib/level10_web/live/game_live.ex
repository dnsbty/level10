defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10.Games

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    # TODO: Make sure the game has started. If not, redirect them to the lobby

    if Games.exists?(join_code) && Games.player_exists?(join_code, player_id) do
      assigns = [
        join_code: params["join_code"],
        player_id: params["player_id"]
      ]

      Games.subscribe(params["join_code"])

      {:ok, assign(socket, assigns)}
    else
      {:ok, push_redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    ~L"""
    <span>Hello</span>
    """
  end
end

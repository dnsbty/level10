defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10.Games
  alias Level10Web.GameView

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with true <- Games.exists?(join_code),
         true <- Games.started?(join_code),
         true <- Games.player_exists?(join_code, player_id) do
      Games.subscribe(params["join_code"])
      players = Games.get_players(join_code)
      hand = Games.get_hand_for_player(join_code, player_id)

      assigns = [
        hand: hand,
        join_code: params["join_code"],
        player_id: params["player_id"],
        players: players
      ]

      {:ok, assign(socket, assigns)}
    else
      _ ->
        {:ok, push_redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    GameView.render("game.html", assigns)
  end
end

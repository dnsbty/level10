defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10.Games
  alias Games.Levels
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
      scores = Games.get_scores(join_code)
      levels = levels_from_scores(scores)
      player_level = levels[player_id]
      discard_top = Games.get_top_discarded_card(join_code)

      assigns = [
        discard_top: discard_top,
        hand: hand,
        join_code: params["join_code"],
        levels: levels,
        player_id: params["player_id"],
        player_level: player_level,
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

  @spec levels_from_scores(Games.scores()) :: %{optional(Player.id()) => Levels.level()}
  defp levels_from_scores(scores) do
    levels_list =
      Enum.map(scores, fn {player_id, {level_number, _}} ->
        level = Levels.by_number(level_number)
        {player_id, level}
      end)

    Enum.into(levels_list, %{})
  end
end

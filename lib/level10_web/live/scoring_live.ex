defmodule Level10Web.ScoringLive do
  @moduledoc """
  LiveView for displaying scores between rounds and at the end of the game.
  """

  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}

  alias Level10.Games
  alias Level10Web.ScoringView

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with true <- Games.exists?(join_code),
         true <- Games.started?(join_code),
         true <- Games.player_exists?(join_code, player_id) do
      scores = Games.get_scores(join_code)
      players = join_code |> Games.get_players() |> sort_players(scores)
      {:ok, assign(socket, players: players, player_id: player_id, scores: scores)}
    end
  end

  def render(assigns) do
    ScoringView.render("index.html", assigns)
  end

  # Private

  defp sort_players(players, scores) do
    Enum.sort(players, fn %{id: player1}, %{id: player2} ->
      {level1, score1} = scores[player1]
      {level2, score2} = scores[player2]

      cond do
        level1 > level2 -> true
        level1 < level2 -> false
        true -> score1 <= score2
      end
    end)
  end
end
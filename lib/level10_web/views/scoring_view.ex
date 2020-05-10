defmodule Level10Web.ScoringView do
  use Level10Web, :view

  @spec level(Game.scoring(), Player.id()) :: non_neg_integer()
  def level(scores, player_id) do
    {level, _} = scores[player_id]
    level
  end

  @spec score(Game.scoring(), Player.id()) :: non_neg_integer()
  def score(scores, player_id) do
    {_, score} = scores[player_id]
    score
  end
end

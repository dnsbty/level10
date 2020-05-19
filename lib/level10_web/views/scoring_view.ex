defmodule Level10Web.ScoringView do
  use Level10Web, :view

  @spec button_text(map()) :: String.t()
  def button_text(%{finished: true}), do: "End Game"
  def button_text(%{starting: true}), do: "Starting..."
  def button_text(_), do: "Next Round"

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

  @spec winner_text(Player.t(), Player.id()) :: String.t()
  def winner_text(%{id: player_id}, player_id), do: "You win!"
  def winner_text(winner, _), do: "#{winner.name} wins"
end

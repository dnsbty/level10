defmodule Level10Web.ScoringComponents do
  @moduledoc """
  Provides UI components for the score screen.
  """

  use Phoenix.Component

  @spec button_text(map()) :: String.t()
  def button_text(%{finished: true}), do: "End Game"
  def button_text(%{starting: true}), do: "Starting..."
  def button_text(_), do: "Next Round"

  @spec level(Game.scoring(), Player.id()) :: String.t()
  def level(scores, player_id) do
    {level, _} = scores[player_id]
    if level == 11, do: " 🏆", else: " (#{level})"
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

defmodule Level10.Games do
  @moduledoc """
  This context module handles all of the work around running games. Most of the
  functions will take in a game struct and manipulate that struct and return
  it.
  """

  alias Level10.Games.{Card, Game}

  @doc """
  At the end of a round, the game struct should be passed into this function.
  It will update player scoring and levels, check if the game has been
  complete, and reset the state for the next round.
  """
  @spec complete_round(Game.t()) :: Game.t()
  def complete_round(game) do
    game
    |> update_scoring_and_levels()
    |> check_complete()
    |> clear_round()
  end

  @spec update_scoring_and_levels(Game.t()) :: Game.t()
  defp update_scoring_and_levels(%{scoring: scoring, table: table, hands: hands} = game) do
    new_scoring =
      scoring
      |> Enum.map(fn {player, {level, score}} ->
        player_hand = hands[player]
        score_for_hand = player_hand |> Enum.map(&Card.score/1) |> Enum.sum()
        new_score = score + score_for_hand

        player_advanced = !is_nil(table[player])
        new_level = if player_advanced, do: level + 1, else: level

        {player, {new_level, new_score}}
      end)
      |> Enum.into(%{})

    %{game | scoring: new_scoring}
  end

  @spec check_complete(Game.t()) :: Game.t()
  defp check_complete(%{scoring: scoring} = game) do
    complete = Enum.any?(scoring, fn {_, {level, _}} -> level == 11 end)
    %{game | complete: complete}
  end

  @spec clear_round(Game.t()) :: Game.t()
  defp clear_round(game) do
    %{game | draw_pile: [], discard_pile: [], table: %{}, hands: %{}}
  end
end

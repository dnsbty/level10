defmodule Level10.Games.Levels do
  @moduledoc """
  The game typically goes through 10 levels. This module contains the details
  for those levels so that they can be grabbed when needed.
  """

  alias Level10.Games.{Card, Game}

  @type type :: :color | :set | :run
  @type count :: non_neg_integer()
  @type group :: {group(), count()}
  @type level :: list(group())

  @levels %{
    1 => [set: 3, set: 3],
    2 => [set: 3, run: 4],
    3 => [set: 4, run: 4],
    4 => [run: 7],
    5 => [run: 8],
    6 => [run: 9],
    7 => [set: 4, set: 4],
    8 => [color: 7],
    9 => [set: 5, set: 2],
    10 => [set: 5, set: 3]
  }

  @doc """
  Returns the level requirements for the level number provided

  ## Examples

      iex> by_number(1)
      [set: 3, set: 3]
  """
  @spec by_number(integer()) :: Keyword.t()
  def by_number(level_number) do
    Map.get(@levels, level_number)
  end

  @doc """
  Returns whether the cards provided are valid for the group provided

  ## Examples

      iex> valid_group({:set, 3}, [
      ...>   %Card{value: :three, color: :green},
      ...>   %Card{value: :three, color: :red},
      ...>   %Card{value: :three, color: :blue}
      ...> ])
      true

      iex> valid_group?({:set, 3}, [%Card{value: :three, color: :green}])
      false
  """
  @spec valid_group?(group(), Game.cards()) :: boolean()
  def valid_group?({_, count}, cards) when length(cards) < count, do: false
  def valid_group?({:color, _}, [%{color: color} | rest]), do: valid_color?(color, rest)
  def valid_group?({:run, _}, [%{value: value} | rest]), do: valid_run?(value, rest)
  def valid_group?({:set, _}, [%{value: value} | rest]), do: valid_set?(value, rest)

  # Private

  @spec next_value(Card.value()) :: Card.value()
  defp next_value(value) do
    case value do
      :one -> :two
      :two -> :three
      :three -> :four
      :four -> :five
      :five -> :six
      :six -> :seven
      :seven -> :eight
      :eight -> :nine
      :nine -> :ten
      :ten -> :eleven
      :eleven -> :twelve
      _ -> nil
    end
  end

  @spec valid_color?(Card.color(), Game.cards()) :: boolean()
  defp valid_color?(color, [%{color: color} | rest]), do: valid_color?(color, rest)
  defp valid_color?(_, []), do: true
  defp valid_color?(_, _), do: false

  @spec valid_set?(Card.value(), Game.cards()) :: boolean()
  defp valid_set?(value, [%{value: value} | rest]), do: valid_set?(value, rest)
  defp valid_set?(_, []), do: true
  defp valid_set?(_, _), do: false

  @spec valid_run?(Card.value(), Game.cards()) :: boolean()
  defp valid_run?(value, [%{value: next_value} | rest]) do
    if next_value(value) == next_value, do: valid_run?(next_value, rest), else: false
  end

  defp valid_run?(_, []), do: true
end

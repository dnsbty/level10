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

      iex> valid_group?({:set, 3}, [
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

  def valid_group?({type, _}, cards) do
    {wild_count, cards} = pop_wilds(cards)
    valid_group?(type, cards, wild_count)
  end

  @doc """
  Returns whether the "table" given is valid for the level provided

  ## Examples

      iex> valid_level?(2, %{
      ...>   0 => [
      ...>     %Card{value: :twelve, color: :green},
      ...>     %Card{value: :twelve, color: :blue},
      ...>     %Card{value: :twelve, color: :yellow}
      ...>   ],
      ...>   1 => [
      ...>     %Card{value: :wild, color: :red},
      ...>     %Card{value: :four, color: :green},
      ...>     %Card{value: :five, color: :blue},
      ...>     %Card{value: :seven, color: :yello}
      ...>   ]
      ...> })
      true

      iex> valid_level?(1, %{0 => [%Card{value: :twelve, color: :green}]})
      false
  """
  @spec valid_level?(non_neg_integer(), Game.table()) :: boolean()
  def valid_level?(level_number, table) do
    level_number
    |> by_number()
    |> Enum.with_index()
    |> Enum.all?(fn {group, position} -> valid_group?(group, table[position]) end)
  end

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

  @spec pop_wilds(Game.cards()) :: {non_neg_integer(), Game.cards()}
  defp pop_wilds(cards) do
    Enum.reduce(cards, {0, []}, fn card, {wild_count, group} ->
      case card.value do
        :wild -> {wild_count + 1, group}
        _ -> {wild_count, [card | group]}
      end
    end)
  end

  @spec valid_color?(Card.color(), Game.cards()) :: boolean()
  defp valid_color?(color, [%{color: color} | rest]), do: valid_color?(color, rest)
  defp valid_color?(_, []), do: true
  defp valid_color?(_, _), do: false

  @spec valid_group?(type(), Game.cards(), non_neg_integer()) :: boolean()
  defp valid_group?(_, [], _), do: true
  defp valid_group?(:color, [%{color: color} | rest], _), do: valid_color?(color, rest)

  defp valid_group?(:run, cards, wild_count) do
    [%{value: value} | rest] = Enum.sort(cards, Card)
    valid_run?(value, rest, wild_count)
  end

  defp valid_group?(:set, [%{value: value} | rest], _), do: valid_set?(value, rest)

  @spec valid_run?(Card.value(), Game.cards(), non_neg_integer()) :: boolean()
  defp valid_run?(value, [%{value: next_value} | rest], 0) do
    if next_value(value) == next_value, do: valid_run?(next_value, rest, 0), else: false
  end

  defp valid_run?(previous_value, [%{value: value} | rest] = cards, wild_count) do
    case next_value(previous_value) do
      ^value -> valid_run?(value, rest, wild_count)
      next_value -> valid_run?(next_value, cards, wild_count - 1)
    end
  end

  defp valid_run?(_, [], _), do: true

  @spec valid_set?(Card.value(), Game.cards()) :: boolean()
  defp valid_set?(value, [%{value: value} | rest]), do: valid_set?(value, rest)
  defp valid_set?(_, []), do: true
  defp valid_set?(_, _), do: false
end

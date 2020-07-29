defmodule Level10.Games.Card do
  @moduledoc """
  A struct to represent a card within the game.
  """

  @type t :: %__MODULE__{}
  @type color :: :black | :blue | :green | :red | :yellow
  @type value ::
          :one
          | :two
          | :three
          | :four
          | :five
          | :six
          | :seven
          | :eight
          | :nine
          | :ten
          | :eleven
          | :twelve
          | :skip
          | :wild

  @single_digit ~W[one two three four five six seven eight nine]a
  @double_digit ~W[ten eleven twelve]a

  defstruct [:color, :value]

  @doc """
  Compare one card to another. This function should typically only be called by
  a sorting function.

  ## Examples

      iex> compare(%Card{color: :green, value: :twelve}, %Card{color: :red, value: :eight})
      :gt

      iex> compare(%Card{color: :green, value: :twelve}, %Card{color: :red, value: :twelve})
      :eq

      iex> compare(%Card{color: :green, value: :twelve}, %Card{color: :black, value: :skip})
      :lt
  """
  @spec compare(t(), t()) :: :lt | :eq | :gt
  def compare(%{value: value1}, %{value: value2}) do
    case {numeric_value(value1), numeric_value(value2)} do
      {first, second} when first > second -> :gt
      {first, second} when first < second -> :lt
      _ -> :eq
    end
  end

  @doc """
  Returns the value atom for the specified number.

  ## Examples

      iex> from_number(3)
      :three

      iex> from_number(12)
      :twelve
  """
  @spec from_number(non_neg_integer()) :: value()
  def from_number(number) do
    case number do
      1 -> :one
      2 -> :two
      3 -> :three
      4 -> :four
      5 -> :five
      6 -> :six
      7 -> :seven
      8 -> :eight
      9 -> :nine
      10 -> :ten
      11 -> :eleven
      12 -> :twelve
    end
  end

  @doc """
  Convenience function for creating a new Wild or Skip card struct

  ## Examples

      iex> new(:wild)
      %Card{color: :black, value: :wild}

      iex> new(:skip)
      %Card{color: :black, value: :skip}

      iex> new(3)
      %Card{color: :black, value: :three}
  """
  @spec new(:skip | :wild | non_neg_integer()) :: t()
  def new(value) when value in [:skip, :wild], do: %__MODULE__{color: :black, value: value}
  def new(value) when is_integer(value), do: %__MODULE__{color: :black, value: from_number(value)}

  @doc """
  Convenience function for creating a new Card struct

  ## Examples

      iex> new(:twelve, :green)
      %Card{color: :green, value: :twelve}
  """
  @spec new(value() | non_neg_integer(), color()) :: t()
  def new(value, color) do
    %__MODULE__{
      color: color,
      value: value
    }
  end

  @doc """
  Removes all wilds from the group and counts them to be used for properly
  sorting runs.

  ## Examples

      iex> pop_wilds([
      ...>   %Card{color: :green, value: :twelve},
      ...>   %Card{color: :red, value: :ten},
      ...>   %Card{color: :black, value: :wild},
      ...>   %Card{color: :yellow, value: :nine}
      ...> ])
      {1, [
        %Card{color: :yellow, value: :nine},
        %Card{color: :red, value: :ten},
        %Card{color: :green, value: :twelve}
      ]}
  """
  @spec pop_wilds(Game.cards()) :: {non_neg_integer(), Game.cards()}
  def pop_wilds(cards) do
    Enum.reduce(cards, {0, []}, fn card, {wild_count, group} ->
      case card.value do
        :wild -> {wild_count + 1, group}
        _ -> {wild_count, [card | group]}
      end
    end)
  end

  @doc """
  Returns the score value for the provided card.

  ## Examples

      iex> score(%Card{color: :red, value: :three})
      5

      iex> score(%Card{color: :green, value: :twelve})
      10

      iex> score(%Card{color: :black, value: :skip})
      15

      iex> score(%Card{color: :black, value: :wild})
      25
  """
  @spec score(t()) :: non_neg_integer()
  def score(card)
  def score(%{value: value}) when value in @single_digit, do: 5
  def score(%{value: value}) when value in @double_digit, do: 10
  def score(%{value: :skip}), do: 15
  def score(%{value: :wild}), do: 25

  @doc """
  Take a list of cards and sort it numerically from lowest to highest. Puts
  wilds at the beginning and skips at the end. An optional second argument can
  be passed `:desc` to sort the cards from highest to lowest, rather than the
  default lowest to highest.

  ## Examples

      iex> sort([
      ...>   %Card{color: :green, value: :twelve},
      ...>   %Card{color: :red, value: :eight},
      ...>   %Card{color: :black, value: :skip},
      ...>   %Card{color: :black, value: :wild}
      ...> ])
      [
        %Card{color: :black, value: :wild},
        %Card{color: :red, value: :eight},
        %Card{color: :green, value: :twelve},
        %Card{color: :black, value: :skip}
      ]

      iex> sort([
      ...>   %Card{color: :green, value: :twelve},
      ...>   %Card{color: :red, value: :eight},
      ...>   %Card{color: :black, value: :skip},
      ...>   %Card{color: :black, value: :wild}
      ...> ], :desc)
      [
        %Card{color: :black, value: :skip},
        %Card{color: :green, value: :twelve},
        %Card{color: :red, value: :eight},
        %Card{color: :black, value: :wild}
      ]
  """
  @spec sort(list(t()), :asc | :desc) :: list(t())
  def sort(cards, order \\ :asc) do
    Enum.sort(cards, {order, __MODULE__})
  end

  @doc """
  Sort a list of cards with wilds based on the requirements its intended to
  fulfill.

  ## Examples
      iex> sort_for_group(:color, [
      ...>   Card.new(:six, :green),
      ...>   Card.new(:wild),
      ...>   Card.new(:eight, :green),
      ...>   Card.new(:wild),
      ...>   Card.new(:three, :green),
      ...>   Card.new(:one, :green),
      ...>   Card.new(:nine, :green)
      ...> ])
      [
        %Card{color: :green, value: :wild},
        %Card{color: :green, value: :wild},
        %Card{color: :green, value: :nine},
        %Card{color: :green, value: :one},
        %Card{color: :green, value: :three},
        %Card{color: :green, value: :eight},
        %Card{color: :green, value: :six}
      ]

      iex> sort_for_group(:run, [
      ...>   %Card{color: :green, value: :six},
      ...>   %Card{color: :red, value: :eight},
      ...>   %Card{color: :blue, value: :five},
      ...>   %Card{color: :black, value: :wild}
      ...> ])
      [
        %Card{color: :blue, value: :five},
        %Card{color: :green, value: :six},
        %Card{color: :black, value: :seven},
        %Card{color: :red, value: :eight}
      ]

      iex> sort_for_group(:set, [
      ...>   %Card{color: :green, value: :twelve},
      ...>   %Card{color: :black, value: :wild},
      ...>   %Card{color: :red, value: :twelve}
      ...> ])
      [
        %Card{color: :black, value: :twelve},
        %Card{color: :red, value: :twelve},
        %Card{color: :green, value: :twelve}
      ]
  """
  @spec sort_for_group(:color | :run | :set, list(t())) :: list(t())
  def sort_for_group(:color, cards) do
    {wild_count, cards} = pop_wilds(cards)
    [%{color: color} | _] = cards
    wilds = List.duplicate(new(:wild, color), wild_count)
    wilds ++ cards
  end

  def sort_for_group(:run, cards) do
    {wild_count, cards} = pop_wilds(cards)
    cards = sort(cards, :desc)
    put_wilds_in_run(cards, wild_count, [])
  end

  def sort_for_group(:set, cards) do
    {wild_count, cards} = pop_wilds(cards)
    [%{value: value} | _] = cards
    wilds = List.duplicate(new(value, :black), wild_count)
    wilds ++ cards
  end

  @doc """
  Converts a card struct into a string for easy printing

  ## Examples

      iex> Card.to_string(%Card{color: :green, value: :twelve})
      "Green 12"

      iex> Card.to_string(%Card{color: :black, value: :skip})
      "Skip"

      iex> Card.to_string(%Card{color: :black, value: :wild})
      "Wild"
  """
  @spec to_string(t()) :: String.t()
  def to_string(%{color: :black, value: value}) do
    value_string(value)
  end

  def to_string(%{color: color, value: value}) do
    color = color |> Atom.to_string() |> String.capitalize()
    value = value_string(value)
    "#{color} #{value}"
  end

  # Private

  @spec numeric_value(value()) :: non_neg_integer()
  defp numeric_value(value) do
    case value do
      :wild -> 0
      :one -> 1
      :two -> 2
      :three -> 3
      :four -> 4
      :five -> 5
      :six -> 6
      :seven -> 7
      :eight -> 8
      :nine -> 9
      :ten -> 10
      :eleven -> 11
      :twelve -> 12
      :skip -> 13
    end
  end

  @spec put_wilds_in_run(Game.cards(), non_neg_integer(), Game.cards()) :: Game.cards()
  defp put_wilds_in_run([], 0, run), do: run

  defp put_wilds_in_run([], wild_count, run) do
    Enum.reduce(1..wild_count, run, fn _, run -> [new(:wild) | run] end)
  end

  defp put_wilds_in_run([card | remaining], wild_count, []) do
    put_wilds_in_run(remaining, wild_count, [card])
  end

  defp put_wilds_in_run([card | remaining], 0, run) do
    put_wilds_in_run(remaining, 0, [card | run])
  end

  defp put_wilds_in_run([card | remaining], wild_count, [last | _] = run) do
    last_value = numeric_value(last.value)
    value = numeric_value(card.value)

    case last_value - value do
      num when num <= 1 ->
        # if the two cards are just 1 number apart, they are left as is
        put_wilds_in_run(remaining, wild_count, [card | run])

      num ->
        # if the two cards are more than 1 number apart, inject wilds between
        # them to bridge the gap
        num_wilds = min(num - 1, wild_count)

        run =
          Enum.reduce(1..num_wilds, run, fn offset, run ->
            [new(last_value - offset) | run]
          end)

        put_wilds_in_run(remaining, wild_count - num_wilds, [card | run])
    end
  end

  @spec value_string(value()) :: String.t()
  defp value_string(value) when value in [:skip, :wild] do
    value |> Atom.to_string() |> String.capitalize()
  end

  defp value_string(value), do: value |> numeric_value() |> Integer.to_string()
end

defimpl String.Chars, for: Level10.Games.Card do
  defdelegate to_string(card), to: Level10.Games.Card
end

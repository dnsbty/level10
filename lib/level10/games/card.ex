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

  @derive Jason.Encoder
  defstruct [:color, :value]

  @doc """
  Returns the color atom for the specified string.

  ## Examples

      iex> color_from_string("red")
      :red
  """
  @spec color_from_string(String.t()) :: color()
  def color_from_string("black"), do: :black
  def color_from_string("blue"), do: :blue
  def color_from_string("green"), do: :green
  def color_from_string("red"), do: :red
  def color_from_string("yellow"), do: :yellow

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
  def from_number(1), do: :one
  def from_number(2), do: :two
  def from_number(3), do: :three
  def from_number(4), do: :four
  def from_number(5), do: :five
  def from_number(6), do: :six
  def from_number(7), do: :seven
  def from_number(8), do: :eight
  def from_number(9), do: :nine
  def from_number(10), do: :ten
  def from_number(11), do: :eleven
  def from_number(12), do: :twelve

  @doc """
  Return a Card struct from a map containing color and value keys.

  Returns nil if either of the fields isn't set to a valid value.

  ## Examples

      iex> from_json(%{"color" => "green", "value" => "three"})
      %Card{color: :green, value: :three}
  """
  @spec from_json(map()) :: t() | nil
  def from_json(%{"color" => color, "value" => value}) do
    if is_nil(color) || is_nil(value) do
      nil
    else
      %__MODULE__{color: color_from_string(color), value: value_from_string(value)}
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

    case cards do
      [] ->
        List.duplicate(new(:wild, :black), wild_count)

      [%{value: value} | _] ->
        wilds = List.duplicate(new(value, :black), wild_count)
        wilds ++ cards
    end
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

  @doc """
  Returns the value atom for the string provided.

  ## Examples

      iex> value_from_string("wild")
      :wild

      iex> value_from_string("three")
      :three
  """
  @spec value_from_string(String.t()) :: value()
  def value_from_string("wild"), do: :wild
  def value_from_string("one"), do: :one
  def value_from_string("two"), do: :two
  def value_from_string("three"), do: :three
  def value_from_string("four"), do: :four
  def value_from_string("five"), do: :five
  def value_from_string("six"), do: :six
  def value_from_string("seven"), do: :seven
  def value_from_string("eight"), do: :eight
  def value_from_string("nine"), do: :nine
  def value_from_string("ten"), do: :ten
  def value_from_string("eleven"), do: :eleven
  def value_from_string("twelve"), do: :twelve
  def value_from_string("skip"), do: :skip

  # Private

  @spec numeric_value(value()) :: non_neg_integer()
  defp numeric_value(:wild), do: 0
  defp numeric_value(:one), do: 1
  defp numeric_value(:two), do: 2
  defp numeric_value(:three), do: 3
  defp numeric_value(:four), do: 4
  defp numeric_value(:five), do: 5
  defp numeric_value(:six), do: 6
  defp numeric_value(:seven), do: 7
  defp numeric_value(:eight), do: 8
  defp numeric_value(:nine), do: 9
  defp numeric_value(:ten), do: 10
  defp numeric_value(:eleven), do: 11
  defp numeric_value(:twelve), do: 12
  defp numeric_value(:skip), do: 13

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

  defp put_wilds_in_run([card | remaining], wild_count, run = [last | _]) do
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

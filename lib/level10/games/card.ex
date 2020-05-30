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
  Convenience function for creating a new Wild or Skip card struct

  ## Examples

      iex> new(:wild)
      %Card{color: :black, value: :wild}

      iex> new(:skip)
      %Card{color: :black, value: :skip}
  """
  @spec new(:skip | :wild) :: t()
  def new(value) when value in [:skip, :wild], do: %__MODULE__{color: :black, value: value}

  @doc """
  Convenience function for creating a new Card struct

  ## Examples

      iex> new(:twelve, :green)
      %Card{color: :green, value: :twelve}
  """
  @spec new(value(), color()) :: t()
  def new(value, color) do
    %__MODULE__{
      color: color,
      value: value
    }
  end

  @spec score(t()) :: non_neg_integer()
  def score(card)
  def score(%{value: value}) when value in @single_digit, do: 5
  def score(%{value: value}) when value in @double_digit, do: 10
  def score(%{value: :skip}), do: 15
  def score(%{value: :wild}), do: 25

  @doc """
  Take a list of cards and sort it numerically from lowest to highest. Puts
  wilds at the beginning and skips at the end.

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
  """
  @spec sort(list(t())) :: list(t())
  def sort(cards) do
    Enum.sort(cards, __MODULE__)
  end

  @doc """
  Converts a card struct into a string for easy printing

  ## Examples

      iex> to_string(%Card{color: :green, value: :twelve})
      "Green 12"

      iex> to_string(%Card{color: :black, value: :skip})
      "Skip"

      iex> to_string(%Card{color: :black, value: :wild})
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

  @spec value_string(value()) :: String.t()
  defp value_string(value) when value in [:skip, :wild] do
    value |> Atom.to_string() |> String.capitalize()
  end

  defp value_string(value), do: value |> numeric_value() |> Integer.to_string()
end

defimpl String.Chars, for: Level10.Games.Card do
  defdelegate to_string(card), to: Level10.Games.Card
end

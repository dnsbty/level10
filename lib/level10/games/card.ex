defmodule Level10.Games.Card do
  @single_digit ~W[one two three four five six seven eight nine]a
  @double_digit ~W[ten eleven twelve]a

  defstruct [:color, :value]

  def new(value, color) do
    %__MODULE__{
      color: color,
      value: value
    }
  end

  def score(card)
  def score(%{value: value}) when value in @single_digit, do: 5
  def score(%{value: value}) when value in @double_digit, do: 10
  def score(%{value: :skip}), do: 15
  def score(%{value: :wild}), do: 25
end

defmodule Level10Web.GameView do
  use Level10Web, :view

  alias Level10.Game.Levels

  @spec background_class(atom()) :: String.t()
  def background_class(:blue), do: "bg-blue-600"
  def background_class(:green), do: "bg-green-600"
  def background_class(:red), do: "bg-red-600"
  def background_class(:yellow), do: "bg-yellow-600"

  @doc """
  Returns the action to be taken when clicking on the discard pile, depending
  on whether or not the user has drawn a card yet.

  ## Examples

      iex> discard_pile_action(true, true)
  """
  @spec discard_pile_action(boolean(), boolean()) :: String.t()
  def discard_pile_action(is_player_turn, has_drawn_card)
  def discard_pile_action(false, _), do: ""
  def discard_pile_action(true, true), do: "phx-click=discard "
  def discard_pile_action(true, false), do: "phx-click=draw_card "

  @doc """
  Returns the list of classes that should apply to the discard pile depending
  on its color and whether or not there is a card present
  """
  @spec discard_styles(Card.t() | nil) :: String.t()
  def discard_styles(nil) do
    "text-xs py-5 border border-purple-400 text-purple-400"
  end

  def discard_styles(%{color: color}) do
    background_class(color) <> " text-4xl py-2 border-4 border-white text-white"
  end

  @spec level_group_name(Levels.level()) :: String.t()
  def level_group_name({:set, count}), do: "Set of #{count}"
  def level_group_name({:run, count}), do: "Run of #{count}"
  def level_group_name({:color, count}), do: "#{count} of one Color"

  @spec number(atom()) :: String.t()
  def number(:one), do: "1"
  def number(:two), do: "2"
  def number(:three), do: "3"
  def number(:four), do: "4"
  def number(:five), do: "5"
  def number(:six), do: "6"
  def number(:seven), do: "7"
  def number(:eight), do: "8"
  def number(:nine), do: "9"
  def number(:ten), do: "10"
  def number(:eleven), do: "11"
  def number(:twelve), do: "12"
  def number(:skip), do: "S"
  def number(:wild), do: "W"

  @doc """
  Takes in a card's position in the player's hand and a MapSet containing all
  of the selected card positions and returns the appropriate CSS classes based
  on whether or not the card has been selected.

  ## Examples

      iex> card_selection(4, MapSet.new([4]))
      "opacity-100"

      iex> card_selection(4, MapSet.new())
      "opacity-75"
  """
  @spec card_selection(non_neg_integer(), list(non_neg_integer())) :: String.t()
  def card_selection(position, selected_positions) do
    if MapSet.member?(selected_positions, position) do
      "opacity-100"
    else
      "opacity-75"
    end
  end
end

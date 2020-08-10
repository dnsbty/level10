defmodule Level10Web.DisplayView do
  use Level10Web, :view

  alias Level10.Games.Card
  alias Level10Web.GameView

  @spec background_class(atom()) :: String.t()
  def background_class(:blue), do: "bg-blue-600"
  def background_class(:green), do: "bg-green-600"
  def background_class(:red), do: "bg-red-600"
  def background_class(:yellow), do: "bg-yellow-600"

  @spec card_back :: String.t()
  def card_back do
    GameView.render("card_back.html")
  end

  @spec card_height(list(Player.t())) :: String.t()
  def card_height(players) do
    if length(players) > 3, do: "h-16", else: "h-20"
  end

  @doc """
  Returns the list of classes that should apply to the discard pile depending
  on its color and whether or not there is a card present
  """
  @spec discard_styles(Card.t() | nil) :: String.t()
  def discard_styles(%Card{}), do: ""

  def discard_styles(nil) do
    "text-xs py-5 border border-purple-400 text-purple-400"
  end

  @doc """
  Returns the HEX code for the fill color of the card based on its color.
  """
  @spec fill_color(Card.color()) :: String.t()
  def fill_color(:black), do: "1A202C"
  def fill_color(:red), do: "E53E3E"
  def fill_color(:yellow), do: "D69E2E"
  def fill_color(:green), do: "38A169"
  def fill_color(:blue), do: "3182CE"

  @spec level(Game.scoring(), Player.id()) :: non_neg_integer()
  def level(scores, player_id) do
    {level, _} = scores[player_id]
    level
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
  Returns the correct opacity CSS class based on whether or not it's the
  player's turn at the moment

  ## Examples

      iex> player_opacity("ee0b3c7b-14ee-4c5e-9dbe-8ea54f6593f4", "0f7b6d5b-ff98-4509-8a5a-01b74ebbed3f")
      "opacity-25"

      iex> player_opacity("ee0b3c7b-14ee-4c5e-9dbe-8ea54f6593f4", "ee0b3c7b-14ee-4c5e-9dbe-8ea54f6593f4")
      "opacity-100"
  """
  @spec player_opacity(String.t(), String.t()) :: String.t()
  def player_opacity(player_id, player_id), do: "opacity-100"
  def player_opacity(_, _), do: "opacity-50"

  @spec render_card(Card.t()) :: String.t()
  def render_card(card) do
    GameView.render("card.html", card: card, selected: false)
  end

  @spec score(Game.scoring(), Player.id()) :: non_neg_integer()
  def score(scores, player_id) do
    {_, score} = scores[player_id]
    score
  end
end

defmodule Level10Web.GameView do
  use Level10Web, :view

  alias Level10.Games.{Card, Game, Levels, Player}

  @happy_emoji ~w(🎉 😄 😎 🤩 🤑 🔥)
  @sad_emoji ~w(💥 💩 😈 🥴 😧 😑 😡 🤬 😵 😩 😢 😭 😒 😔)

  @spec background_class(atom()) :: String.t()
  def background_class(:blue), do: "bg-blue-600"
  def background_class(:green), do: "bg-green-600"
  def background_class(:red), do: "bg-red-600"
  def background_class(:yellow), do: "bg-yellow-600"

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

  @doc """
  Returns the emoji to be displayed upon completion of a round. Returns happy
  if the player successfully completed their level, and sad if they didn't.

  ## Examples

      iex> complete_emoji(%{}, [])
      "🎉"
  """
  @spec complete_emoji(Game.table(), Player.id()) :: String.t()
  def complete_emoji(table, player_id) do
    case table[player_id] do
      nil -> Enum.random(@sad_emoji)
      _ -> Enum.random(@happy_emoji)
    end
  end

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
  def discard_styles(%Card{}), do: ""

  def discard_styles(nil) do
    "text-xs py-5 border border-purple-400 text-purple-400"
  end

  @doc """
  Returns the HEX code for the fill color of the card based on its color and
  whether or not it has been selected.
  """
  @spec fill_color(Card.color(), boolean()) :: String.t()
  def fill_color(:black, false), do: "1A202C"
  def fill_color(:black, true), do: "4A5568"
  def fill_color(:red, false), do: "E53E3E"
  def fill_color(:red, true), do: "FC8181"
  def fill_color(:yellow, false), do: "D69E2E"
  def fill_color(:yellow, true), do: "F6E05E"
  def fill_color(:green, false), do: "38A169"
  def fill_color(:green, true), do: "68D391"
  def fill_color(:blue, false), do: "3182CE"
  def fill_color(:blue, true), do: "63B3ED"

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

  @spec render_card(Card.t(), boolean()) :: String.t()
  def render_card(card, selected \\ false) do
    render("card.html", card: card, selected: selected)
  end

  @doc """
  Returns the name of the player given, or "You" if the player matches the ID given.
  """
  @spec round_winner(Player.t(), Player.id()) :: String.t()
  def round_winner(%{id: player_id}, player_id), do: "You"
  def round_winner(%{name: name}, _), do: name

  @doc """
  Returns the SVG path for the value specified.
  """
  @spec value_path(Card.value()) :: String.t()
  def value_path(:wild),
    do:
      "M169.3 123.8c5.8 0 9.4 3.3 9.4 8.6 0 1.7-.3 4-1 6.3l-19 69c-1.9 6.6-5.2 9.5-11 9.5-6.1 0-9.5-2.8-11.3-9.6l-15.1-53.7h-.6l-15 53.7c-1.9 6.6-5.3 9.6-11.2 9.6-6 0-9.3-2.9-11.2-9.7l-19-68.8c-.6-2.3-1-4.6-1-6.3 0-5.3 3.6-8.6 9.4-8.6 5 0 8 2.8 9.2 8.2l13.6 59h.5l15.3-58.6c1.4-6 4.4-8.6 9.7-8.6 5.2 0 8.3 2.8 9.7 8.4L146 191h.5l13.6-58.9c1.2-5.4 4.3-8.2 9.2-8.2z"

  def value_path(:skip),
    do:
      "M121 123.5c16.7 0 29.2 7 33.2 18.9.5 1.2.7 2.5.7 4.2 0 4.5-3.3 7.6-8.1 7.6-4.3 0-7-1.7-9-5.6-3.1-6.9-9-9.7-16.8-9.7-9.4 0-15.6 4.4-15.6 11 0 5.7 4.4 9.2 15.1 11.3l9.6 2c19.3 3.8 27.6 11.5 27.6 25.3 0 17.8-14 29-36.6 29-18.8 0-30.8-7.5-34.5-17.4-.6-1.7-1-3.4-1-5.1a8 8 0 018.4-8.4c4 0 6.5 1.5 8.8 5.5 3 7 10 10.1 18.7 10.1 10.2 0 17.2-5 17.2-11.6 0-6-4.3-9.4-15.7-11.7l-9.7-1.9c-18-3.6-27-12.3-27-25.8 0-16.6 14.5-27.7 34.7-27.7z"

  def value_path(:one),
    do:
      "M127.2 123.7c6.7 0 10.8 4.1 10.8 10.7v73.4c0 5.7-3.8 9.5-9.4 9.5-5.6 0-9.5-3.8-9.5-9.5v-65h-.3l-13.3 9.2a7.7 7.7 0 01-5 1.7 6.5 6.5 0 01-6.7-6.8c0-2.9 1-5 4-7.1l18-12.5c4.5-3 7.5-3.6 11.4-3.6z"

  def value_path(:two),
    do:
      "M121 123c19.4 0 32.3 11 32.3 26.5 0 11.1-5.4 18-20.2 32.1l-19.7 18.9v.4h34.3c4.9 0 7.8 3 7.8 7.5s-3 7.6-7.8 7.6H97.3c-6 0-8.9-3.3-8.9-8.1 0-3.6 1.4-6 5.2-9.5l27.1-26c11.2-10.7 14.1-15.1 14.1-21.7 0-7.5-5.8-12.8-13.9-12.8-7.3 0-12.3 3.6-15.6 11-2.2 3.7-4.4 5.5-8.5 5.5-5 0-8-3-8-7.8 0-1.4.2-2.7.6-4 3.1-10.1 14.5-19.5 31.7-19.5z"

  def value_path(:three),
    do:
      "M120.4 123c19.2 0 32.2 9.6 32.2 24.2 0 11.5-8.2 19-19 21.2v.4c13.6 1.3 22.4 9.2 22.4 21.8 0 16.5-14.3 27.4-35.4 27.4-17.4 0-28-7.5-32.3-16.4-1-2.1-1.4-4.1-1.4-6 0-5 3.1-8 8.3-8 3.8 0 6.2 1.5 8.1 5 3.2 6.3 8.1 10.1 17.6 10.1 9.3 0 15.7-5.4 15.7-13 0-8.8-6.4-13.7-17.4-13.7h-4c-4.6 0-7.2-2.7-7.2-6.8 0-4 2.6-6.7 7.2-6.7h3.7c9.5 0 15.7-5.2 15.7-12.6 0-7.3-5-12.2-14.1-12.2-7.7 0-12.3 3.2-15.3 9.6-2 4.3-4.3 5.9-8.6 5.9-5.3 0-8-3-8-7.7 0-2.1.5-4 1.4-6 4-9 14.4-16.4 30.4-16.4z"

  def value_path(:four),
    do:
      "M131.4 123.7c9.6 0 15.7 5.3 15.7 13.8V184h5.1c5 0 7.9 3.2 7.9 7.6 0 4.5-2.9 7.6-7.9 7.6h-5.1v8.8c0 6-3.9 9.2-9 9.2-5.3 0-9.1-3.2-9.1-9.2v-8.8H95.1c-6.9 0-11.5-4.3-11.5-10.6 0-4 1.2-7.5 4-12.4 6.3-11.3 15.3-25.1 25.2-39.8 6.3-9.6 11-12.8 18.6-12.8zm-2 15.2h-.4a459.1 459.1 0 00-28.7 45.2v.5h29V139z"

  def value_path(:five),
    do:
      "M144.7 125.1c4.7 0 7.8 3 7.8 7.6s-3 7.5-7.8 7.5h-36l-2 25.3h.3c3.7-5.9 11.2-9.5 20.4-9.5a28.5 28.5 0 0129.8 29.5c0 19.4-14.5 32.5-35.2 32.5-14.4 0-27-6.7-31.5-16.4-1-2-1.6-4-1.6-6.2 0-4.8 3-7.7 8-7.7 3.8 0 6.1 1.3 8.3 4.7a17.6 17.6 0 0016.8 10.5c9.9 0 17-7.1 17-17 0-9.5-7-16.3-17-16.3a19 19 0 00-13 5.4c-3.8 3.5-5.7 4.4-10 4.4-6.2 0-9.1-4.3-8.9-9.4l.1-.8 2.6-33.3c.7-7.7 4.6-10.8 12-10.8z"

  def value_path(:six),
    do:
      "M122.7 123c15 0 25.9 6.4 30.1 14.9 1 1.8 1.4 3.4 1.4 5.1 0 4.2-3 7.5-8 7.5-3.8 0-6-1.6-8.8-4.9a17.5 17.5 0 00-14.8-7.5c-13 0-19.6 12.3-19.7 31.7v1h.4c3.5-8.5 12.4-14.6 24.7-14.6a28.4 28.4 0 0129.6 29.6c0 18.8-14.7 32.2-35 32.2A34.5 34.5 0 0190 198c-3.4-7.1-5.3-16.1-5.3-26.7 0-30.1 14.3-48.3 38-48.3zm-.2 47.2c-9.6 0-16.8 6.7-16.8 16 0 9.4 7.3 16.7 16.7 16.7 9.3 0 16.6-7.2 16.7-16.3 0-9.6-7-16.4-16.6-16.4z"

  def value_path(:seven),
    do:
      "M142.3 125.1c6.6 0 11.3 4 11.3 10.4a24 24 0 01-3.6 11.2l-33.7 65c-2 4.1-4.4 5.6-8.5 5.6-5.3 0-8.7-3.3-8.7-7.7 0-2.2.5-4 1.7-6l33.6-63v-.4H95.2c-4.5 0-7.8-3-7.8-7.6 0-4.5 3.3-7.5 7.8-7.5z"

  def value_path(:eight),
    do:
      "M121 123c19.7 0 33.5 10.4 33.5 24.6 0 9.8-7.2 17.5-17.8 20.2v.4c12.4 2.4 21.1 11.3 21.1 23.2 0 15.8-15.1 26.6-36.8 26.6-21.7 0-36.8-10.9-36.8-26.6 0-12 8.8-20.8 21.2-23.2v-.4c-10.7-2.6-18-10.4-18-20.3 0-14 13.9-24.4 33.6-24.4zm0 53c-10 0-17 5.8-17 14s7 14.2 17 14.2 17-6 17-14.2-7-14-17-14zm0-39.2c-8.6 0-14.7 5.2-14.7 12.7 0 7.4 6 12.6 14.7 12.6 8.6 0 14.7-5.2 14.7-12.6 0-7.5-6.1-12.7-14.7-12.7z"

  def value_path(:nine),
    do:
      "M119.4 123c14.5 0 26 6.8 32.6 20.1 3.4 7 5.3 16 5.3 26.7 0 30.2-14.4 48.2-38.5 48.2-15 0-26.1-7-29.9-15-.9-1.8-1.3-3.4-1.3-5 0-4.2 2.9-7.4 8-7.4 3.8 0 6 1.7 8.7 4.8 4.3 5.1 8.3 7.6 15.2 7.6 13.4 0 19.5-12.8 19.6-31.8v-1h-.4c-3.2 8.8-12.2 14.7-24.2 14.7a29 29 0 01-30.1-29.6c0-18.9 14.7-32.3 35-32.3zm.2 15.2c-9.3 0-16.7 7.1-16.7 16.3a16 16 0 0016.6 16.3c9.6 0 16.8-6.7 16.8-16s-7.3-16.6-16.7-16.6z"

  def value_path(:ten),
    do:
      "M152 123c23 0 37 18 37 47.3 0 29.4-14 47.7-37 47.7s-37.1-18.2-37.1-47.6c0-29.4 14.2-47.4 37-47.4zm-67 .7c6.6 0 10.7 4.1 10.7 10.7v73.4c0 5.7-3.8 9.5-9.4 9.5-5.6 0-9.5-3.8-9.5-9.5v-65h-.3L63.2 152a7.7 7.7 0 01-5 1.7 6.5 6.5 0 01-6.7-6.8c0-2.9 1-5 4-7.1l18-12.5c4.5-3 7.5-3.6 11.4-3.6zm67 14.6c-11.1 0-17.8 11.4-17.8 32.1 0 20.8 6.6 32.4 17.8 32.4 11.2 0 17.7-11.6 17.7-32.4 0-20.7-6.6-32.1-17.7-32.1z"

  def value_path(:eleven),
    do:
      "M96.2 123.7c6.8 0 10.8 4.1 10.8 10.7v73.4c0 5.7-3.8 9.5-9.4 9.5-5.6 0-9.4-3.8-9.4-9.5v-65h-.4L74.5 152a7.7 7.7 0 01-5 1.7 6.5 6.5 0 01-6.7-6.8c0-2.9 1.1-5 4-7.1L85 127.3c4.4-3 7.4-3.6 11.3-3.6zm62 0c6.7 0 10.7 4.1 10.7 10.7v73.4c0 5.7-3.7 9.5-9.4 9.5-5.6 0-9.4-3.8-9.4-9.5v-65h-.4l-13.3 9.2a7.7 7.7 0 01-5 1.7 6.5 6.5 0 01-6.7-6.8c0-2.9 1.2-5 4.1-7.1l18-12.5c4.4-3 7.5-3.6 11.4-3.6z"

  def value_path(:twelve),
    do:
      "M88.3 123.7c6.7 0 10.8 4.1 10.8 10.7v73.4c0 5.7-3.8 9.5-9.4 9.5-5.6 0-9.5-3.8-9.5-9.5v-65H80L66.6 152a7.7 7.7 0 01-5 1.7 6.5 6.5 0 01-6.7-6.8c0-2.9 1.1-5 4-7.1l18-12.5c4.5-3 7.5-3.6 11.4-3.6zm63.8-.6c19.2 0 32.2 10.8 32.2 26.4 0 11.1-5.4 18-20.3 32.1l-19.6 18.9v.4h34.2c5 0 8 3 8 7.5s-3 7.6-8 7.6h-50.3c-6 0-9-3.3-9-8.1 0-3.6 1.4-6 5.3-9.5l27-26c11.3-10.7 14.2-15.1 14.2-21.7 0-7.5-5.8-12.8-14-12.8-7.2 0-12.3 3.6-15.6 11-2.1 3.7-4.3 5.5-8.4 5.5-5.1 0-8.1-3-8.1-7.8 0-1.4.2-2.7.7-4 3-10.1 14.5-19.5 31.7-19.5z"
end

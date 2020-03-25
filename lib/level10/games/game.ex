defmodule Level10.Games.Game do
  @moduledoc """
  The game struct is used to represent the state for an entire game. It is a
  token that will be passed to different functions in order to modify the
  game's state, and then stored on the server to be updated or to serve data
  down to clients.
  """
  alias Level10.Games.{Card, Player}

  @type join_code :: String.t()
  @type t :: %__MODULE__{
          current_round: non_neg_integer() | :pending | :completed,
          discard_pile: [Card.t()],
          draw_pile: [Card.t()],
          hands: %{optional(Player.id()) => [Card.t()]},
          join_code: join_code(),
          players: [Player.t()],
          scoring: %{optional(Player.id()) => {non_neg_integer(), non_neg_integer()}},
          table: %{optional(Player.id()) => keyword([Card.t()])}
        }

  defstruct ~W[
    current_round
    discard_pile
    draw_pile
    hands
    join_code
    players
    scoring
    table
  ]a

  @doc """
  At the end of a round, the game struct should be passed into this function.
  It will update player scoring and levels, check if the game has been
  complete, and reset the state for the next round.

  Make private later.
  """
  @spec complete_round(t()) :: t()
  def complete_round(game) do
    game
    |> update_scoring_and_levels()
    |> check_complete()
    |> clear_round()
  end

  @spec update_scoring_and_levels(t()) :: t()
  defp update_scoring_and_levels(%{scoring: scoring, table: table, hands: hands} = game) do
    scoring =
      Map.new(scoring, fn {player, {level, score}} ->
        hand = hands[player]

        hand_score =
          hand
          |> Stream.map(&Card.score/1)
          |> Enum.sum()

        score = score + hand_score

        case table do
          %{^player => _} ->
            {player, {level + 1, score}}

          _table ->
            {player, {level, score}}
        end
      end)

    %{game | scoring: scoring}
  end

  @spec check_complete(t()) :: t()
  defp check_complete(%{scoring: scoring} = game) do
    if Enum.any?(scoring, &match?({_player, {_level = 11, _score}}, &1)) do
      %{game | current_round: :completed}
    else
      game
    end
  end

  @spec clear_round(t()) :: t()
  defp clear_round(game) do
    %{game | draw_pile: [], discard_pile: [], table: %{}, hands: %{}}
  end

  @spec generate_join_code() :: join_code()
  def generate_join_code do
    <<:random.uniform(1_048_576)::40>>
    |> Base.encode32()
    |> binary_part(4, 4)
  end

  @spec new(join_code(), Player.t()) :: t()
  def new(join_code, player) do
    game = %__MODULE__{
      current_round: :pending,
      discard_pile: [],
      draw_pile: [],
      hands: %{},
      join_code: join_code,
      players: [],
      scoring: %{},
      table: %{}
    }

    {:ok, game} = put_player(game, player)
    game
  end

  @spec put_player(t(), Player.t()) :: {:ok, t()} | :already_started
  def put_player(game, player)

  def put_player(game = %{current_round: :pending, players: players, scoring: scoring}, player) do
    players = players ++ [player]
    scoring = Map.put(scoring, player.id, {1, 0})

    {:ok, %{game | players: players, scoring: scoring}}
  end

  def put_player(_game, _player) do
    :already_started
  end

  @doc """
  Shuffles the discard pile to make a new draw pile. This should happen when
  the current draw pile is empty.

  Another one to make private, this time when one attempts to draw a card from an empty draw pile.
  """
  @spec reshuffle_deck(t()) :: t()
  def reshuffle_deck(game = %{discard_pile: discard_pile}) do
    %{game | discard_pile: [], draw_pile: Enum.shuffle(discard_pile)}
  end

  @spec start_round(t()) :: t()
  def start_round(game) do
    case increment_current_round(game) do
      {:ok, game} ->
        game =
          game
          |> put_new_deck()
          |> deal_hands()

        {:ok, game}

      :game_over ->
        :game_over
    end
  end

  @spec increment_current_round(t()) :: t()
  defp increment_current_round(game)

  defp increment_current_round(%{current_round: :completed}) do
    :game_over
  end

  defp increment_current_round(game = %{current_round: :pending}) do
    {:ok, %{game | current_round: 1}}
  end

  defp increment_current_round(game = %{current_round: current_round}) do
    {:ok, %{game | current_round: current_round + 1}}
  end

  @spec put_new_deck(t()) :: t()
  defp put_new_deck(game) do
    %{game | draw_pile: new_deck()}
  end

  @spec new_deck() :: [Card.t()]
  defp new_deck do
    color_cards =
      for value <- ~W[one two three four five six seven eight nine ten eleven twelve wild]a,
          color <- ~W[blue green red yellow]a,
          card = Card.new(value, color),
          _repeat <- 1..2 do
        card
      end

    skips = for _repeat <- 1..4, do: Card.new(:skip, :blue)

    color_cards
    |> Stream.concat(skips)
    |> Enum.shuffle()
  end

  @spec deal_hands(t()) :: t()
  defp deal_hands(game = %{draw_pile: deck, players: players}) do
    {hands, deck} =
      Enum.reduce(players, {%{}, deck}, fn %{id: player_id}, {hands, deck} ->
        {hand, deck} = Enum.split(deck, 10)
        hands = Map.put(hands, player_id, hand)
        {hands, deck}
      end)

    %{game | draw_pile: deck, hands: hands}
  end
end

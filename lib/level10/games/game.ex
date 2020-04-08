defmodule Level10.Games.Game do
  @moduledoc """
  The game struct is used to represent the state for an entire game. It is a
  token that will be passed to different functions in order to modify the
  game's state, and then stored on the server to be updated or to serve data
  down to clients.
  """
  require Logger
  alias Level10.Games.{Card, Player}

  @type join_code :: String.t()
  @type t :: %__MODULE__{
          current_player: Player.t(),
          current_round: non_neg_integer(),
          current_stage: :finish | :lobby | :play | :score,
          current_turn: non_neg_integer(),
          current_turn_drawn?: boolean(),
          discard_pile: [Card.t()],
          draw_pile: [Card.t()],
          hands: %{optional(Player.id()) => [Card.t()]},
          join_code: join_code(),
          players: [Player.t()],
          scoring: %{optional(Player.id()) => {non_neg_integer(), non_neg_integer()}},
          table: %{optional(Player.id()) => keyword([Card.t()])}
        }

  defstruct ~W[
    current_player
    current_round
    current_stage
    current_turn
    current_turn_drawn?
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
      %{game | current_stage: :finish}
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

  @spec delete_player(t(), Player.id()) :: t()
  def delete_player(game, player_id)

  def delete_player(game = %{current_stage: :lobby, players: players}, player_id) do
    {:ok, %{game | players: Enum.filter(players, &(&1.id != player_id))}}
  end

  def delete_player(game, player_id) do
    metadata = [game_id: game.join_code, player_id: player_id]
    Logger.warn("Player tried to leave game that has already started", metadata)

    :already_started
  end

  @spec discard(t(), Card.t()) :: t()
  def discard(game, card)

  def discard(game = %{current_turn_drawn?: false}, _card) do
    game
  end

  def discard(game = %{current_player: player, discard_pile: pile, hands: hands}, card) do
    hands = Map.update!(hands, player.id, &List.delete(&1, card))
    pile = [card | pile]
    game = %{game | discard_pile: pile, hands: hands}
    increment_current_turn(game)
  end

  @spec draw_card(t(), :draw_pile | :discard_pile) :: t()
  def draw_card(game, pile)

  def draw_card(game = %{current_turn_drawn?: true}, _pile) do
    game
  end

  def draw_card(game = %{current_player: player, draw_pile: pile, hands: hands}, :draw_pile) do
    case pile do
      [card | pile] ->
        hands = Map.update!(hands, player.id, &[card | &1])
        %{game | current_turn_drawn?: true, draw_pile: pile, hands: hands}

      [] ->
        game
        |> reshuffle_deck()
        |> draw_card(:draw_pile)
    end
  end

  def draw_card(game = %{discard_pile: []}, :discard_pile) do
    game
  end

  def draw_card(game, :discard_pile) do
    %{current_player: player, discard_pile: [card | pile], hands: hands} = game
    hands = Map.update!(hands, player.id, &[card | &1])
    %{game | current_turn_drawn?: true, discard_pile: pile, hands: hands}
  end

  @spec new(join_code(), Player.t()) :: t()
  def new(join_code, player) do
    game = %__MODULE__{
      current_player: player,
      current_round: 0,
      current_stage: :lobby,
      current_turn: 0,
      current_turn_drawn?: false,
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

  # TODO move scoring into start game
  def put_player(game = %{current_stage: :lobby, players: players, scoring: scoring}, player) do
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

  @doc """
  Starts the game.

  Checks to make sure that there are at least two players present.
  """
  @spec start_game(t()) :: {:ok, t()} | :single_player
  def start_game(%{players: players}) when length(players) < 2, do: :single_player

  def start_game(game) do
    case start_round(game) do
      {:ok, game} -> {:ok, game}
      :game_over -> raise "Trying to start finished game: #{game.join_code}"
    end
  end

  @doc """
  Sets everything up to start the next round. Shuffles and deals a new deck and
  all hands.
  """
  @spec start_round(t()) :: t()
  def start_round(game) do
    case increment_current_round(game) do
      {:ok, game} ->
        game =
          game
          |> increment_current_turn()
          |> put_new_deck()
          |> deal_hands()

        {:ok, game}

      :game_over ->
        :game_over
    end
  end

  @spec increment_current_turn(t()) :: t()
  defp increment_current_turn(game = %{current_turn: current_turn, players: players}) do
    total_players = length(players)
    player_index = rem(current_turn + 1, total_players)
    player = Enum.at(players, player_index)
    %{game | current_turn: current_turn + 1, current_turn_drawn?: false, current_player: player}
  end

  @spec increment_current_round(t()) :: t()
  defp increment_current_round(game)

  defp increment_current_round(%{current_stage: :finish}) do
    :game_over
  end

  defp increment_current_round(game = %{current_stage: :lobby}) do
    {:ok, %{game | current_round: 1, current_stage: :play}}
  end

  defp increment_current_round(game = %{current_round: current_round}) do
    {:ok, %{game | current_round: current_round + 1, current_turn: 0}}
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

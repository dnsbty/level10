defmodule Level10.Games.Game do
  @moduledoc """
  The game struct is used to represent the state for an entire game. It is a
  token that will be passed to different functions in order to modify the
  game's state, and then stored on the server to be updated or to serve data
  down to clients.
  """
  require Logger
  alias Level10.Games.{Card, Levels, Player}

  @type cards :: list(Card.t())
  @type join_code :: String.t()
  @type level :: non_neg_integer()
  @type levels :: %{optional(Player.id()) => level()}
  @type player_table :: %{non_neg_integer() => cards()}
  @type score :: non_neg_integer()
  @type scores :: %{optional(Player.id()) => scoring()}
  @type scoring :: {level(), score()}
  @type table :: %{optional(Player.id()) => player_table()}
  @type t :: %__MODULE__{
          current_player: Player.t(),
          current_round: non_neg_integer(),
          current_stage: :finish | :lobby | :play | :score,
          current_turn: non_neg_integer(),
          current_turn_drawn?: boolean(),
          discard_pile: cards(),
          draw_pile: cards(),
          hands: %{optional(Player.id()) => cards()},
          join_code: join_code(),
          levels: levels(),
          players: [Player.t()],
          players_ready: MapSet.t(),
          scoring: scores(),
          table: table()
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
    levels
    players
    players_ready
    scoring
    table
  ]a

  @doc """
  Add cards from one player's hand onto the table group of another player.

  ## Examples

      iex> add_to_table(%Game{}, "1cb7cd3d-a385-4c4e-a9cf-c5477cf52ecd", "5a4ef76d-a260-4a17-8b54-bc1fa7159607", 1, [%Card{}])
      {:ok, %Game{}}
  """
  @spec add_to_table(t(), Player.id(), Player.id(), non_neg_integer(), Game.cards()) ::
          {:ok | :invalid_group | :level_incomplete | :needs_to_draw | :not_your_turn, t()}
  def add_to_table(game, current_player_id, group_player_id, position, cards_to_add) do
    # get the level requirement for the specified group
    requirement = group_requirement(game, group_player_id, position)

    # make sure the player is doing this when they should and using valid cards
    with ^current_player_id <- game.current_player.id,
         {:current_turn_drawn?, true} <- {:current_turn_drawn?, game.current_turn_drawn?},
         {:level_complete?, true} <- {:level_complete?, level_complete?(game, current_player_id)},
         group when is_list(group) <- get_group(game.table, group_player_id, position),
         new_group = group ++ cards_to_add,
         true <- Levels.valid_group?(requirement, new_group) do
      # update the table to include the new cards and remove them from the player's hand
      sorted_group = Card.sort(new_group)
      table = put_in(game.table, [group_player_id, position], sorted_group)
      hands = %{game.hands | current_player_id => game.hands[current_player_id] -- cards_to_add}
      {:ok, %{game | hands: hands, table: table}}
    else
      nil ->
        {:invalid_group, game}

      false ->
        {:invalid_group, game}

      {:current_turn_drawn?, _} ->
        {:needs_to_draw, game}

      {:level_complete?, _} ->
        {:level_incomplete, game}

      player_id when is_binary(player_id) ->
        {:not_your_turn, game}
    end
  end

  @spec get_group(table(), Player.id(), non_neg_integer()) :: Game.cards() | nil
  defp get_group(table, player_id, position) do
    get_in(table, [player_id, position])
  end

  @spec group_requirement(t(), Player.id(), non_neg_integer()) :: Levels.group()
  defp group_requirement(game, player_id, position) do
    game.levels
    |> Map.get(player_id)
    |> Levels.by_number()
    |> Enum.at(position)
  end

  @spec level_complete?(t(), Player.id()) :: boolean()
  defp level_complete?(game, player_id), do: !is_nil(game.table[player_id])

  @doc """
  At the end of a round, the game struct should be passed into this function.
  It will update player scoring and levels, check if the game has been
  complete, and reset the state for the next round.
  """
  @spec complete_round(t()) :: t()
  def complete_round(game) do
    game
    |> update_scoring_and_levels()
    |> check_complete()
    |> clear_ready()
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

    %{game | current_stage: :scoring, scoring: scoring}
  end

  @spec check_complete(t()) :: t()
  defp check_complete(%{scoring: scoring} = game) do
    if Enum.any?(scoring, &match?({_player, {_level = 11, _score}}, &1)) do
      %{game | current_stage: :finish}
    else
      game
    end
  end

  @doc """
  Return the creator of the game

  ## Examples

      iex> creator(%Game{})
      %Player{}
  """
  @spec creator(t()) :: Player.t()
  def creator(game) do
    List.last(game.players)
  end

  @spec generate_join_code() :: join_code()
  def generate_join_code do
    <<:rand.uniform(1_048_576)::40>>
    |> Base.encode32()
    |> binary_part(4, 4)
  end

  @spec delete_player(t(), Player.id()) :: {:ok, t()} | :already_started
  def delete_player(game, player_id)

  def delete_player(game = %{current_stage: :lobby, players: players}, player_id) do
    game = %{game | players: Enum.filter(players, &(&1.id != player_id))}
    if game.players == [], do: :empty_game, else: {:ok, game}
  end

  def delete_player(game, player_id) do
    metadata = [game_id: game.join_code, player_id: player_id]
    Logger.warn("Player tried to leave game that has already started", metadata)

    :already_started
  end

  @spec discard(t(), Card.t()) :: t() | :needs_to_draw
  def discard(game, card)

  def discard(%{current_turn_drawn?: false}, _card) do
    :needs_to_draw
  end

  def discard(game = %{current_player: player, discard_pile: pile, hands: hands}, card) do
    hands = Map.update!(hands, player.id, &List.delete(&1, card))
    pile = [card | pile]
    game = %{game | discard_pile: pile, hands: hands}
    increment_current_turn(game, card.value == :skip)
  end

  @spec draw_card(t(), Player.id(), :draw_pile | :discard_pile) ::
          {:ok | :already_drawn | :empty_discard_pile | :not_your_turn | :skip, t()}
  def draw_card(game, player_id, pile)

  def draw_card(game = %{current_player: %{id: current_id}}, player_id, _)
      when current_id != player_id do
    {:not_your_turn, game}
  end

  def draw_card(game = %{current_turn_drawn?: true}, _player_id, _pile) do
    {:already_drawn, game}
  end

  def draw_card(game = %{draw_pile: pile, hands: hands}, player_id, :draw_pile) do
    case pile do
      [card | pile] ->
        hands = Map.update!(hands, player_id, &[card | &1])
        {:ok, %{game | current_turn_drawn?: true, draw_pile: pile, hands: hands}}

      [] ->
        game
        |> reshuffle_deck()
        |> draw_card(player_id, :draw_pile)
    end
  end

  def draw_card(game = %{discard_pile: []}, _player_id, :discard_pile) do
    {:empty_discard_pile, game}
  end

  def draw_card(game = %{discard_pile: [%{value: :skip} | _]}, _player_id, :discard_pile) do
    {:skip, game}
  end

  def draw_card(game, player_id, :discard_pile) do
    %{discard_pile: [card | pile], hands: hands} = game
    hands = Map.update!(hands, player_id, &[card | &1])
    {:ok, %{game | current_turn_drawn?: true, discard_pile: pile, hands: hands}}
  end

  @doc """
  Get the number of cards in each player's hand.

  ## Examples

      iex> hand_counts(%Game{})
      %{"c07a54ff-08c1-4a25-98a2-3694e42855ed" => 10, "ccdd4cba-3fcf-4e5d-a41f-a7f9511f1461" => 3}
  """
  @spec hand_counts(t()) :: %{optional(Player.id()) => non_neg_integer()}
  def hand_counts(game) do
    game.hands
    |> Enum.map(fn {player_id, hand} -> {player_id, length(hand)} end)
    |> Enum.into(%{})
  end

  @doc """
  Marks a player as being ready for the next round. If the player is the final
  player to mark themself as ready, this will return an `:all_ready` atom as
  the first element in the tuple to show that all players are now ready for the
  next round to begin.

  ## Examples

      iex> mark_player_ready(%Game{}, "2ebbee1f-cb54-4446-94d6-3a01e4afe8ef")
      {:ok, %Game{}}

      iex> mark_player_ready(%Game{}, "0f2dd2ab-11f8-4c55-aaa2-499f695f1327")
      {:all_ready, %Game{}}
  """
  @spec mark_player_ready(t(), Player.id()) :: {:ok | :all_ready, t()}
  def mark_player_ready(game, player_id) do
    players_ready = MapSet.put(game.players_ready, player_id)
    total_players = length(game.players)
    status = if MapSet.size(players_ready) == total_players, do: :all_ready, else: :ok
    {status, %{game | players_ready: players_ready}}
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
      levels: %{},
      players: [],
      players_ready: MapSet.new(),
      scoring: %{},
      table: %{}
    }

    {:ok, game} = put_player(game, player)
    game
  end

  @spec get_player(t(), Player.id()) :: Player.t()
  def get_player(game, player_id), do: Enum.find(game, &(&1.id == player_id))

  @spec put_player(t(), Player.t()) :: {:ok, t()} | :already_started
  def put_player(game, player)

  def put_player(game = %{current_stage: :lobby, players: players}, player) do
    {:ok, %{game | players: [player | players]}}
  end

  def put_player(_game, _player) do
    :already_started
  end

  @doc """
  Shuffles the discard pile to make a new draw pile. This should happen when
  the current draw pile is empty.

  Another one to make private, this time when one attempts to draw a card from
  an empty draw pile.
  """
  @spec reshuffle_deck(t()) :: t()
  def reshuffle_deck(game = %{discard_pile: discard_pile}) do
    %{game | discard_pile: [], draw_pile: Enum.shuffle(discard_pile)}
  end

  @doc """
  Check whether the current round was just finished by the specified player.

  ## Examples

      iex> round_finished?(%Game{}, "aa08dd0d-5486-4b9d-a15c-98445c13dffd")
      true
  """
  @spec round_finished?(t(), Player.id()) :: boolean()
  def round_finished?(game, player_id), do: game.hands[player_id] == []

  @doc """
  Returns the player who won the current round. Returns `nil` if the round
  isn't over yet.
  """
  @spec round_winner(t()) :: Player.t() | nil
  def round_winner(game) do
    case Enum.find(game.hands, fn {_, hand} -> hand == [] end) do
      {player_id, _} -> Enum.find(game.players, fn %{id: id} -> id == player_id end)
      _ -> nil
    end
  end

  @doc """
  Set a player's table to the given cards
  """
  @spec set_player_table(t(), Player.id(), player_table()) ::
          {:ok | :already_set | :invalid_level | :needs_to_draw | :not_your_turn, t()}
  def set_player_table(game, player_id, player_table) do
    with ^player_id <- game.current_player.id,
         {:drawn, true} <- {:drawn, game.current_turn_drawn?},
         nil <- Map.get(game.table, player_id),
         {level_number, _} <- game.scoring[player_id],
         true <- Levels.valid_level?(level_number, player_table) do
      # sort the table so that runs will show up as expected
      player_table =
        for {position, cards} <- player_table, do: {position, Card.sort(cards)}, into: %{}

      table = Map.put(game.table, player_id, player_table)
      cards_used = Enum.reduce(player_table, [], fn {_, cards}, acc -> acc ++ cards end)
      player_hand = game.hands[player_id] -- cards_used
      hands = Map.put(game.hands, player_id, player_hand)
      {:ok, %{game | hands: hands, table: table}}
    else
      player_id when is_binary(player_id) -> {:not_your_turn, game}
      false -> {:invalid_level, game}
      {:drawn, false} -> {:needs_to_draw, game}
      _ -> {:already_set, game}
    end
  end

  @doc """
  Starts the game.

  Checks to make sure that there are at least two players present.
  """
  @spec start_game(t()) :: {:ok, t()} | :single_player
  def start_game(%{players: players}) when length(players) < 2, do: :single_player

  def start_game(game) do
    game = put_empty_scores(game)

    case start_round(game) do
      {:ok, game} -> {:ok, game}
      :game_over -> raise "Trying to start finished game: #{game.join_code}"
    end
  end

  @spec put_empty_scores(t()) :: t()
  defp put_empty_scores(game = %{players: players}) do
    %{game | scoring: Map.new(players, &{&1.id, {1, 0}})}
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
          |> clear_table()
          |> put_new_deck()
          |> deal_hands()
          |> update_levels()
          |> put_new_discard()

        [%{value: value}] = game.discard_pile

        {:ok, increment_current_turn(game, value == :skip)}

      :game_over ->
        :game_over
    end
  end

  @doc """
  Returns the top card in the discard pile for the specified game. Returns nil
  if the discard pile is currently empty.

  ## Examples

      iex> top_discarded_card(%Game{})
      %Card{color: :green, value: :twelve}

      iex> top_discarded_card(%Game{})
      nil
  """
  @spec top_discarded_card(t()) :: Card.t() | nil
  def top_discarded_card(game) do
    case game.discard_pile do
      [] -> nil
      [top_card | _] -> top_card
    end
  end

  @spec clear_ready(t()) :: t()
  defp clear_ready(game), do: %{game | players_ready: MapSet.new()}

  @spec clear_table(t()) :: t()
  defp clear_table(game), do: %{game | table: %{}}

  @spec increment_current_turn(t(), boolean()) :: t()
  defp increment_current_turn(game, skip) do
    %{current_turn: current_turn, players: players} = game
    increment = if skip, do: 2, else: 1
    total_players = length(players)
    player_index = rem(current_turn + increment, total_players)
    player = Enum.at(players, player_index)
    turn = current_turn + increment

    %{game | current_turn: turn, current_turn_drawn?: false, current_player: player}
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

  @spec new_deck() :: cards()
  defp new_deck do
    color_cards =
      for value <- ~W[one two three four five six seven eight nine ten eleven twelve]a,
          color <- ~W[blue green red yellow]a,
          card = Card.new(value, color),
          _repeat <- 1..2 do
        card
      end

    skips = for _repeat <- 1..4, do: Card.new(:skip)
    wilds = for _repeat <- 1..8, do: Card.new(:wild)

    color_cards
    |> Stream.concat(skips)
    |> Stream.concat(wilds)
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

  @spec update_levels(t()) :: t()
  defp update_levels(game = %{scoring: scores}) do
    levels = for {player_id, {level, _}} <- scores, do: {player_id, level}, into: %{}
    %{game | levels: levels}
  end

  @spec put_new_discard(Game.t()) :: Game.t()
  defp put_new_discard(game = %{draw_pile: [top_card | rest]}) do
    %{game | discard_pile: [top_card], draw_pile: rest}
  end
end

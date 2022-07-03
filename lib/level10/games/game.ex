defmodule Level10.Games.Game do
  @moduledoc """
  The game struct is used to represent the state for an entire game. It is a
  token that will be passed to different functions in order to modify the
  game's state, and then stored on the server to be updated or to serve data
  down to clients.
  """
  require Logger
  alias Level10.Games.{Card, Levels, Player, Settings}

  @type cards :: list(Card.t())
  @type join_code :: String.t()
  @type level :: non_neg_integer()
  @type levels :: %{optional(Player.id()) => level()}
  @type player_table :: %{non_neg_integer() => cards()}
  @type score :: non_neg_integer()
  @type scores :: %{optional(Player.id()) => scoring()}
  @type scoring :: {level(), score()}
  @type stage :: :finish | :lobby | :play | :score
  @type table :: %{optional(Player.id()) => player_table()}
  @type t :: %__MODULE__{
          current_player: Player.t(),
          current_round: non_neg_integer(),
          current_stage: stage(),
          current_turn: non_neg_integer(),
          current_turn_drawn?: boolean(),
          device_tokens: %{optional(Player.id()) => String.t()},
          discard_pile: cards(),
          draw_pile: cards(),
          hands: %{optional(Player.id()) => cards()},
          join_code: join_code(),
          levels: levels(),
          players: [Player.t()],
          players_ready: MapSet.t(),
          remaining_players: MapSet.t(),
          scoring: scores(),
          settings: Settings.t(),
          skipped_players: MapSet.t(),
          table: table()
        }

  defstruct ~W[
    current_player
    current_round
    current_stage
    current_turn
    current_turn_drawn?
    device_tokens
    discard_pile
    draw_pile
    hands
    join_code
    levels
    players
    players_ready
    remaining_players
    scoring
    settings
    skipped_players
    table
  ]a

  @doc """
  Add cards from one player's hand onto the table group of another player.

  ## Examples

      iex> add_to_table(%Game{}, "1cb7cd3d-a385-4c4e-a9cf-c5477cf52ecd", "5a4ef76d-a260-4a17-8b54-bc1fa7159607", 1, [%Card{}])
      {:ok, %Game{}}
  """
  @spec add_to_table(t(), Player.id(), Player.id(), non_neg_integer(), Game.cards()) ::
          t() | :invalid_group | :level_incomplete | :needs_to_draw | :not_your_turn
  def add_to_table(game, current_player_id, group_player_id, position, cards_to_add) do
    # get the level requirement for the specified group
    requirement = group_requirement(game, group_player_id, position)
    {required_type, _} = requirement

    # make sure the player is doing this when they should and using valid cards
    with ^current_player_id <- game.current_player.id,
         {:current_turn_drawn?, true} <- {:current_turn_drawn?, game.current_turn_drawn?},
         {:level_complete?, true} <- {:level_complete?, level_complete?(game, current_player_id)},
         group when is_list(group) <- get_group(game.table, group_player_id, position),
         new_group = group ++ cards_to_add,
         true <- Levels.valid_group?(requirement, new_group) do
      # update the table to include the new cards and remove them from the player's hand
      sorted_group = Card.sort_for_group(required_type, new_group)
      table = put_in(game.table, [group_player_id, position], sorted_group)
      hands = %{game.hands | current_player_id => game.hands[current_player_id] -- cards_to_add}
      {:ok, %{game | hands: hands, table: table}}
    else
      nil -> :invalid_group
      false -> :invalid_group
      {:current_turn_drawn?, _} -> :needs_to_draw
      {:level_complete?, _} -> :level_incomplete
      player_id when is_binary(player_id) -> :not_your_turn
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
  Returns whether or not all players remaining in the game have marked
  themselves as ready for the next round.
  """
  @spec all_ready?(t()) :: boolean()
  def all_ready?(game) do
    players_ready = MapSet.size(game.players_ready)
    total_players = MapSet.size(game.remaining_players)
    players_ready == total_players
  end

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
  defp update_scoring_and_levels(game = %{scoring: scoring, table: table, hands: hands}) do
    scoring =
      Map.new(scoring, fn {player, {level, score}} ->
        hand = Map.get(hands, player, [])

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

    %{game | current_stage: :score, scoring: scoring}
  end

  @spec check_complete(t()) :: t()
  defp check_complete(game) do
    if Enum.any?(game.scoring, fn {_, {level, _}} -> level == 11 end) do
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

  @spec delete_player(t(), Player.id()) :: {:ok, t()} | :already_started | :empty_game
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
    increment_current_turn(%{game | discard_pile: pile, hands: hands})
  end

  @spec draw_card(t(), Player.id(), :draw_pile | :discard_pile) ::
          {:ok | :already_drawn | :empty_discard_pile | :not_your_turn | :skip, t()}
  def draw_card(game, player_id, pile)

  def draw_card(%{current_player: %{id: current_id}}, player_id, _)
      when current_id != player_id do
    :not_your_turn
  end

  def draw_card(%{current_turn_drawn?: true}, _player_id, _pile) do
    :already_drawn
  end

  def draw_card(game = %{draw_pile: pile, hands: hands}, player_id, :draw_pile) do
    case pile do
      [card | pile] ->
        hands = Map.update!(hands, player_id, &[card | &1])
        %{game | current_turn_drawn?: true, draw_pile: pile, hands: hands}

      [] ->
        game
        |> reshuffle_deck()
        |> draw_card(player_id, :draw_pile)
    end
  end

  def draw_card(%{discard_pile: []}, _player_id, :discard_pile) do
    :empty_discard_pile
  end

  def draw_card(%{discard_pile: [%{value: :skip} | _]}, _player_id, :discard_pile) do
    :skip
  end

  def draw_card(game, player_id, :discard_pile) do
    %{discard_pile: [card | pile], hands: hands} = game
    hands = Map.update!(hands, player_id, &[card | &1])
    %{game | current_turn_drawn?: true, discard_pile: pile, hands: hands}
  end

  @doc """
  Get a player from a game using their ID.

  ## Examples

      iex> get_player(%Game{}, "ce1bdc3c-7e65-472c-9ccf-f926e3403450")
      %Player{id: "ce1bdc3c-7e65-472c-9ccf-f926e3403450", name: "Dennis"}
  """
  @spec get_player(t(), Player.id()) :: Player.t()
  def get_player(game, player_id), do: Enum.find(game, &(&1.id == player_id))

  @doc """
  Generate a random 4 character join code.

  ## Examples

      iex> generate_join_code()
      "ABCD"
  """
  @spec generate_join_code() :: join_code()
  def generate_join_code do
    <<:rand.uniform(1_048_576)::40>>
    |> Base.encode32()
    |> binary_part(4, 4)
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
    total_players = MapSet.size(game.remaining_players)
    status = if MapSet.size(players_ready) == total_players, do: :all_ready, else: :ok
    {status, %{game | players_ready: players_ready}}
  end

  @spec new(join_code(), Player.t(), Settings.t()) :: t()
  def new(join_code, player, settings) do
    game = %__MODULE__{
      current_player: player,
      current_round: 0,
      current_stage: :lobby,
      current_turn: 0,
      current_turn_drawn?: false,
      device_tokens: %{},
      discard_pile: [],
      draw_pile: [],
      hands: %{},
      join_code: join_code,
      levels: %{},
      players: [],
      players_ready: MapSet.new(),
      scoring: %{},
      settings: settings,
      table: %{}
    }

    {:ok, game} = put_player(game, player)
    game
  end

  @doc """
  Get the player whose turn will come after the specified player during the
  current round. This function is used mostly for getting the player to be
  skipped for games that are set to not allow players to choose whom they wish
  to skip.

  ## Examples

      iex> next_player(%Game{}, "b1bbeda1-c6b5-42dd-b0e1-8bed3273dfab")
      %Player{}
  """
  @spec next_player(t(), Player.id()) :: Player.t()
  def next_player(game, player_id) do
    total_players = length(game.players)
    index = Enum.find_index(game.players, fn %{id: id} -> id == player_id end)
    next_player(game.players, index, total_players, game.remaining_players)
  end

  @doc """
  Checks whether or not a given player ID belongs to a player listed in the
  given game
  """
  @spec player_exists?(t(), Player.id()) :: boolean()
  def player_exists?(game, player_id) do
    Enum.any?(game.players, fn player -> player.id == player_id end)
  end

  @doc """
  Returns the players from the given game sorted by their scores from best to
  worst.
  """
  @spec players_by_score(t()) :: list(Player.t())
  def players_by_score(game) do
    %{players: players, remaining_players: remaining, scoring: scores} = game

    Enum.sort(players, fn %{id: player1}, %{id: player2} ->
      {level1, score1} = scores[player1]
      {level2, score2} = scores[player2]

      cond do
        player1 in remaining && player2 not in remaining -> true
        player2 in remaining && player1 not in remaining -> false
        level1 > level2 -> true
        level1 < level2 -> false
        true -> score1 <= score2
      end
    end)
  end

  @spec put_player(t(), Player.t()) :: {:ok, t()} | :already_started
  def put_player(game, player)

  def put_player(game = %{current_stage: :lobby, players: players}, player) do
    {:ok, %{game | players: [player | players]}}
  end

  def put_player(_game, _player) do
    :already_started
  end

  @doc """
  Set a device token for the player so they will receive push notifications.

  Removes the player from the device token map if the token is set to `nil`.

  ## Examples

      iex> put_player_device_token(%Game{}, "fea3c658-e7ae-4976-80ee-4e627f5879d4", "7b38d4bf-ca80-45d1-b2e8-96f3bb381c26")
      %Game{device_tokens: %{"fea3c658-e7ae-4976-80ee-4e627f5879d4" => "7b38d4bf-ca80-45d1-b2e8-96f3bb381c26"}}

      iex> game = %Game{device_tokens: %{"fea3c658-e7ae-4976-80ee-4e627f5879d4" => "7b38d4bf-ca80-45d1-b2e8-96f3bb381c26"}}
      iex> put_player_device_token(game, "fea3c658-e7ae-4976-80ee-4e627f5879d4", nil)
      %Game{device_tokens: %{}}
  """
  @spec put_player_device_token(t(), Player.id(), String.t() | nil) :: t()
  def put_player_device_token(game, player_id, nil) do
    device_tokens = Map.delete(game.device_tokens, player_id)
    %{game | device_tokens: device_tokens}
  end

  def put_player_device_token(game, player_id, device_token) do
    device_tokens = Map.put(game.device_tokens, player_id, device_token)
    %{game | device_tokens: device_tokens}
  end

  @doc """
  Update a setting for configuring the game.
  """
  @spec put_setting(t(), Settings.setting(), boolean()) :: t()
  def put_setting(game, setting_name, value) do
    settings = Settings.set(game.settings, setting_name, value)
    %{game | settings: settings}
  end

  @doc """
  Get the number of players remaining in the game.
  """
  @spec remaining_player_count(t()) :: pos_integer()
  def remaining_player_count(game = %{remaining_players: nil}), do: length(game.players)
  def remaining_player_count(%{remaining_players: remaining}), do: MapSet.size(remaining)

  @doc """
  Remove a player from a game that has started.

  Prior to the game starting, players are free to come and go, and they can
  simply be deleted from the player list. Once the game has been started,
  players can no longer be deleted from the game or else the turn ordering will
  be thrown off.

  For that reason, the game maintains a set of player IDs for players that are
  still remaining in the game. That way every time it's someone else's turn,
  the game can check to make sure they're still in the list of remaining players.

  This function will remove the provided player ID from the set of remaining
  players so that they can still exist in the player list, but the game will
  know that they should no longer be given turns.

  If the next to last player leaves so that there is only a single player
  remaining, the game's stage will also be changed to `:finish`.
  """
  @spec remove_player(t(), Player.id()) :: t()
  def remove_player(game = %{remaining_players: remaining}, player_id) do
    remaining_players = MapSet.delete(remaining, player_id)

    # Also remove the player from the list of players that are ready so that
    # the counts won't be off
    players_ready = MapSet.delete(game.players_ready, player_id)

    game = %{game | players_ready: players_ready, remaining_players: remaining_players}

    case MapSet.size(remaining_players) do
      1 -> %{game | current_stage: :finish}
      _ -> game
    end
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
          t() | :already_set | :invalid_level | :needs_to_draw | :not_your_turn
  def set_player_table(game, player_id, player_table) do
    with ^player_id <- game.current_player.id,
         {:drawn, true} <- {:drawn, game.current_turn_drawn?},
         nil <- Map.get(game.table, player_id),
         {level_number, _} <- game.scoring[player_id],
         true <- Levels.valid_level?(level_number, player_table) do
      # sort the table so that runs will show up as expected
      sorted_player_table = Levels.sort_for_level(level_number, player_table)

      table = Map.put(game.table, player_id, sorted_player_table)
      cards_used = Enum.reduce(player_table, [], fn {_, cards}, acc -> acc ++ cards end)
      player_hand = game.hands[player_id] -- cards_used
      hands = Map.put(game.hands, player_id, player_hand)
      %{game | hands: hands, table: table}
    else
      player_id when is_binary(player_id) -> :not_your_turn
      false -> :invalid_level
      {:drawn, false} -> :needs_to_draw
      _ -> :already_set
    end
  end

  @doc """
  Add a player ID to the list of players who should be skipped on their next
  turn.
  """
  @spec skip_player(t(), Player.id()) :: t() | :already_skipped
  def skip_player(game, player_id) do
    if player_id in game.skipped_players do
      :already_skipped
    else
      %{game | skipped_players: MapSet.put(game.skipped_players, player_id)}
    end
  end

  @doc """
  Starts the game.

  Checks to make sure that there are at least two players present.
  """
  @spec start_game(t()) :: {:ok, t()} | :single_player
  def start_game(%{players: players}) when length(players) < 2, do: :single_player

  def start_game(game) do
    started_game =
      game
      |> put_empty_scores()
      |> put_remaining_players()
      |> start_round()

    case started_game do
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
  @spec start_round(t()) :: {:ok, t()} | :game_over
  def start_round(game) do
    case increment_current_round(game) do
      {:ok, game} ->
        game =
          game
          |> clear_table()
          |> clear_skipped_players()
          |> put_new_deck()
          |> deal_hands()
          |> update_levels()
          |> put_new_discard()
          |> put_stage(:play)

        {:ok, increment_current_turn(game)}

      :game_over ->
        :game_over
    end
  end

  @spec put_stage(t(), stage()) :: t()
  defp put_stage(game, stage) do
    %{game | current_stage: stage}
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

  @spec clear_skipped_players(t()) :: t()
  defp clear_skipped_players(game), do: %{game | skipped_players: MapSet.new()}

  @spec clear_table(t()) :: t()
  defp clear_table(game), do: %{game | table: %{}}

  @spec increment_current_turn(t()) :: t()
  defp increment_current_turn(game) do
    %{current_round: round, current_turn: turn, players: players} = game
    total_players = length(players)
    new_turn = turn + 1
    player_index = rem(round + new_turn, total_players)
    player = Enum.at(players, player_index)

    game = %{game | current_turn: new_turn, current_turn_drawn?: false, current_player: player}

    cond do
      player.id not in game.remaining_players ->
        increment_current_turn(game)

      player.id in game.skipped_players ->
        skipped_players = MapSet.delete(game.skipped_players, player.id)
        increment_current_turn(%{game | skipped_players: skipped_players})

      true ->
        game
    end
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

  @spec next_player(list(Player.t()), non_neg_integer(), non_neg_integer(), MapSet.t(Player.t())) ::
          Player.t()
  defp next_player(players, previous_index, total_players, remaining_players) do
    index = rem(previous_index + 1, total_players)
    player = Enum.at(players, index)

    if player.id in remaining_players do
      player
    else
      next_player(players, index, total_players, remaining_players)
    end
  end

  @spec deal_hands(t()) :: t()
  defp deal_hands(game = %{draw_pile: deck, players: players}) do
    {hands, deck} =
      Enum.reduce(players, {%{}, deck}, fn %{id: player_id}, {hands, deck} ->
        if player_id in game.remaining_players do
          {hand, deck} = Enum.split(deck, 10)
          hands = Map.put(hands, player_id, hand)
          {hands, deck}
        else
          {hands, deck}
        end
      end)

    %{game | draw_pile: deck, hands: hands}
  end

  @spec put_remaining_players(t()) :: t()
  defp put_remaining_players(game = %{players: players}) do
    player_ids = Enum.map(players, & &1.id)
    remaining = MapSet.new(player_ids)
    %{game | remaining_players: remaining}
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

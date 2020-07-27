defmodule Level10.Games do
  @moduledoc """
  This context module handles all of the work around running games. Most of the
  functions will take in a game struct and manipulate that struct and return
  it.
  """

  alias Level10.Games.{Card, Game, GameServer, Levels, Player}
  require Logger

  @typep event_type :: atom()

  @doc """
  Add one or more cards to a group that is already on the table
  """
  @spec add_to_table(Game.join_code(), Player.id(), Player.id(), non_neg_integer(), Game.cards()) ::
          :ok | :invalid_group | :level_incomplete | :needs_to_draw | :not_your_turn
  defdelegate add_to_table(join_code, player_id, table_id, position, cards_to_add), to: GameServer

  @doc """
  Get the current count of active games in play.
  """
  @spec count() :: non_neg_integer()
  defdelegate count, to: GameServer

  @doc """
  Create a new game with the player named as its creator.
  """
  @spec create_game(String.t()) :: {:ok, Game.join_code(), Player.id()} | :error
  defdelegate create_game(player_name), to: GameServer

  @doc """
  Returns a Player struct representing the player who created the game.
  """
  @spec creator(Game.join_code()) :: Player.t()
  defdelegate creator(join_code), to: GameServer

  @doc """
  Check to see if the current player has drawn a card yet.

  ## Examples

      iex> current_player_has_drawn?("ABCD")
      true
  """
  @spec current_player_has_drawn?(Game.join_code()) :: boolean()
  defdelegate current_player_has_drawn?(join_code), to: GameServer

  @doc """
  Delete a game.

  ## Examples

      iex> delete_game("ABCD")
      :ok
  """
  @spec delete_game(Game.join_code()) :: :ok
  defdelegate delete_game(join_code), to: GameServer

  @doc """
  Discard a card from the player's hand

  ## Examples

      iex> discard_card("ABCD", "9c34b9fe-3104-44b3-b21b-28140e2e3624", %Card{color: :green, value: :twelve})
      :ok
  """
  @spec discard_card(Game.join_code(), Player.id(), Card.t()) ::
          :ok | :needs_to_draw | :not_your_turn
  defdelegate discard_card(join_code, player_id, card), to: GameServer

  @doc """
  Take the top card from either the draw pile or discard pile and add it to the
  player's hand

  ## Examples

      iex> draw_card("ABCD", "9c34b9fe-3104-44b3-b21b-28140e2e3624", :draw_pile)
      %Card{color: :green, value: :twelve}

      iex> draw_card("ABCD", "9c34b9fe-3104-44b3-b21b-28140e2e3624", :discard_pile)
      %Card{color: :green, value: :twelve}
  """
  @spec draw_card(Game.join_code(), Player.id(), :discard_pile | :draw_pile) ::
          Card.t() | :already_drawn | :empty_discard_pile | :not_your_turn | :skip
  defdelegate draw_card(join_code, player_id, source), to: GameServer

  @doc """
  Returns whether or not a game with the specified join code exists.

  ## Examples

      iex> exists?("ABCD")
      true

      iex> exists?("ASDF")
      false
  """
  @spec exists?(Game.join_code()) :: boolean()
  defdelegate exists?(join_code), to: GameServer

  @spec finished?(Game.join_code()) :: boolean()
  defdelegate finished?(join_code), to: GameServer

  @doc """
  Returns the game with the specified join code.

  ## Examples

      iex> get("ABCD")
      %Game{}
  """
  @spec get(Game.join_code()) :: Game.t()
  defdelegate get(join_code), to: GameServer

  @doc """
  Get the player whose turn it currently is.

  ## Examples

      iex> get_current_turn("ABCD")
      %Player{id: "ffe6629a-faff-4053-b7b8-83c3a307400f", name: "Player 1"}
  """
  @spec get_current_turn(Game.join_code()) :: Player.t()
  defdelegate get_current_turn(join_code), to: GameServer

  @doc """
  Get the count of cards in each player's hand.

  ## Examples

      iex> get_hand_counts("ABCD")
      %{"179539f0-661e-4b56-ac67-fec916214223" => 10, "000cc69a-bb7d-4d3e-ae9f-e42e3dcac23e" => 3}
  """
  @spec get_hand_counts(Game.join_code()) :: %{optional(Player.id()) => non_neg_integer()}
  defdelegate get_hand_counts(join_code), to: GameServer

  @doc """
  Get the hand of the specified player.

  ## Examples

      iex> get_hand_for_player("ABCD", "557489d0-1ef2-4763-9b0b-d2ea3c80fd99")
      [%Card{color: :green, value: :twelve}, %Card{color: :blue, value: :nine}, ...]
  """
  @spec get_hand_for_player(Game.join_code(), Player.id()) :: list(Card.t())
  defdelegate get_hand_for_player(join_code, player_id), to: GameServer

  @doc """
  Get the level information for each player in the game.

  ## Examples

      iex> get_levels("ABCD")
      %{
        "04ba446e-0b2a-49f2-8dbf-7d9742548842" => [set: 4, run: 4],
        "86800484-8e73-4408-bd15-98a57871694f" => [run: 7],
      }
  """
  @spec get_levels(Game.join_code()) :: %{optional(Player.t()) => Levels.level()}
  defdelegate get_levels(join_code), to: GameServer

  @doc """
  Get the list of players in a game.

  ## Examples

      iex> get_players("ABCD")
      [
        %Player{id: "601a07a1-b229-47e5-ad13-dbe0599c90e9", name: "Player 1"},
        %Player{id: "a0d2ef3e-e44c-4a58-b90d-a56d88224700", name: "Player 2"}
      ]
  """
  @spec get_players(Game.join_code()) :: list(Player.t())
  defdelegate get_players(join_code), to: GameServer

  @doc """
  Gets the set of IDs of players who are ready for the next round to begin.
  """
  @spec get_players_ready(Game.join_code()) :: MapSet.t(Player.id())
  defdelegate get_players_ready(join_code), to: GameServer

  @spec get_round_number(Game.join_code()) :: non_neg_integer()
  defdelegate get_round_number(join_code), to: GameServer

  @doc """
  Get the scores for all players in a game.

  ## Examples

      iex> get_scores("ABCD")
      %{
        "e486056e-4a01-4239-9f00-6f7f57ca8d54" => {3, 55},
        "38379e46-4d29-4a22-a245-aa7013ec3c33" => {2, 120}
      }
  """
  @spec get_scores(Game.join_code()) :: Game.scores()
  defdelegate get_scores(join_code), to: GameServer

  @doc """
  Get the table: the cards that have been played to complete levels by each
  player.

  ## Examples

      iex> get_table("ABCD")
      %{
        "12a29ba6-fe6f-4f81-8c89-46ef8aff4b82" => %{
          0 => [
            %Level10.Games.Card{color: :black, value: :wild},
            %Level10.Games.Card{color: :blue, value: :twelve},
            %Level10.Games.Card{color: :red, value: :twelve}
          ],
          1 => [
            %Level10.Games.Card{color: :black, value: :wild},
            %Level10.Games.Card{color: :green, value: :ten},
            %Level10.Games.Card{color: :blue, value: :ten}
          ]
        }
      }
  """
  @spec get_table(Game.join_code()) :: Game.table()
  defdelegate get_table(join_code), to: GameServer

  @doc """
  Get the top card from the discard pile.

  ## Examples

      iex> get_top_discarded_card("ABCD")
      %Card{color: :green, value: :twelve}

      iex> get_top_discarded_card("ABCD")
      nil
  """
  @spec get_top_discarded_card(Game.join_code()) :: Card.t() | nil
  defdelegate get_top_discarded_card(join_code), to: GameServer

  @doc """
  Attempts to join a game. Will return an ok tuple with the player ID for the
  new player if joining is successful, or an atom with a reason if not.

  ## Examples

      iex> join_game("ABCD", "Player One")
      {:ok, "9bbfeacb-a006-4646-8776-83cca0ad03eb"}

      iex> join_game("ABCD", "Player One")
      :already_started

      iex> join_game("ABCD", "Player One")
      :full

      iex> join_game("ABCD", "Player One")
      :not_found
  """
  @spec join_game(Game.join_code(), String.t()) ::
          {:ok, Player.id()} | :already_started | :full | :not_found
  defdelegate join_game(join_code, player_name), to: GameServer

  @doc """
  Removes the specified player from the game. This is only allowed if the game
  is still in the lobby stage.

  If the player is currently alone in the game, the game will be deleted as
  well.
  """
  @spec leave_game(Game.join_code(), Player.id()) :: :ok | :already_started | :deleted
  defdelegate leave_game(join_code, player_id), to: GameServer

  @doc """
  Stores in the game state that the specified player is ready to move on to the
  next stage of the game.
  """
  @spec mark_player_ready(Game.join_code(), Player.id()) :: :ok
  defdelegate mark_player_ready(join_code, player_id), to: GameServer

  @doc """
  Returns whether or not the specified player exists within the specified game.
  """
  @spec player_exists?(Game.t() | Game.join_code(), Player.id()) :: boolean()
  defdelegate player_exists?(join_code, player_id), to: GameServer

  @doc """
  Check whether or not the current round has started.

  ## Examples

      iex> round_started?("ABCD")
      true

      iex> round_started?("EFGH")
      false
  """
  @spec round_started?(Game.join_code()) :: boolean()
  defdelegate round_started?(join_code), to: GameServer

  @doc """
  Returns the player struct representing the player who won the current round.
  """
  @spec round_winner(Game.join_code()) :: Player.t() | nil
  defdelegate round_winner(join_code), to: GameServer

  @doc """
  Start the next round.
  """
  @spec start_round(Game.join_code()) :: :ok | :game_over
  defdelegate start_round(join_code), to: GameServer

  @doc """
  Start the game.
  """
  @spec start_game(Game.join_code()) :: :ok | :single_player
  defdelegate start_game(join_code), to: GameServer

  @doc """
  Check whether or not a game has started.

  ## Examples

      iex> started?("ABCD")
      true

      iex> started?("EFGH")
      false
  """
  @spec started?(Game.join_code()) :: boolean()
  defdelegate started?(join_code), to: GameServer

  @doc """
  Set the given player's table to the given cards.
  """
  @spec table_cards(Game.join_code(), Player.id(), Game.player_table()) ::
          :ok | :already_set | :needs_to_draw | :not_your_turn
  defdelegate table_cards(join_code, player_id, player_table), to: GameServer

  @doc """
  Susbscribe a process to updates for the specified game.
  """
  @spec subscribe(String.t(), Player.id()) :: :ok | {:error, term()}
  defdelegate subscribe(game_code, player_id), to: GameServer

  @doc """
  Unsubscribe a process from updates for the specified game.
  """
  @spec unsubscribe(String.t(), Player.id()) :: :ok | {:error, term()}
  defdelegate unsubscribe(game_code, player_id), to: GameServer

  @doc """
  Update the specified game using the provided function.
  """
  @spec update(Game.join_code(), (Game.t() -> Game.t())) :: :ok
  defdelegate update(join_code, fun), to: GameServer

  @doc """
  Send an update to all the subscribed processes
  """
  @spec broadcast(Game.join_code(), event_type(), term()) :: :ok | {:error, term()}
  defdelegate broadcast(join_code, event_type, event), to: GameServer

  @doc """
  Get the list of players currently present in the specified game.
  """
  @spec list_presence(Game.join_code()) :: %{optional(Player.id()) => map()}
  defdelegate list_presence(join_code), to: GameServer
end

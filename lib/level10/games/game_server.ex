defmodule Level10.Games.GameServer do
  @moduledoc """
  A server for holding game state
  """

  use GenServer
  alias Level10.StateHandoff
  alias Level10.Games.{Game, GameRegistry, Levels, Player}
  require Logger

  # Types

  @typedoc "The agent reference"
  @type agent :: pid | {atom, node} | name

  @typedoc "The agent name"
  @type name :: atom | {:global, term} | {:via, module, term}

  @typedoc "Return values of `start*` functions"
  @type on_start :: {:ok, pid} | {:error, {:already_started, pid} | term}

  @typedoc "The agent state"
  @type state :: term

  @typep event_type :: atom()
  @typep game_name :: {:via, module, term}

  # Constants

  @max_players 6

  # Client Functions

  @doc """
  Add one or more cards to a group that is already on the table
  """
  @spec add_to_table(Game.join_code(), Player.id(), Player.id(), non_neg_integer(), Game.cards()) ::
          :ok | :invalid_group | :level_incomplete | :needs_to_draw | :not_your_turn
  def add_to_table(join_code, player_id, table_id, position, cards_to_add) do
    GenServer.call(
      via(join_code),
      {:add_to_table, {player_id, table_id, position, cards_to_add}},
      5000
    )
  end

  @doc """
  Returns a Player struct representing the player who created the game.
  """
  @spec creator(Game.join_code()) :: Player.t()
  def creator(join_code) do
    GenServer.call(via(join_code), :creator, 5000)
  end

  @doc """
  Check to see if the current player has drawn a card yet.

  ## Examples

      iex> current_player_has_drawn?("ABCD")
      true
  """
  @spec current_player_has_drawn?(Game.join_code()) :: boolean()
  def current_player_has_drawn?(join_code) do
    GenServer.call(via(join_code), :current_turn_drawn?, 5000)
  end

  @doc """
  Delete a game.

  ## Examples

      iex> delete_game("ABCD")
      :ok
  """
  @spec delete_game(Game.join_code(), reason :: term, timeout) :: :ok
  def delete_game(join_code, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(via(join_code), reason, timeout)
  end

  @doc """
  Discard a card from the player's hand

  ## Examples

      iex> discard_card("ABCD", "9c34b9fe-3104-44b3-b21b-28140e2e3624", %Card{color: :green, value: :twelve})
      :ok
  """
  @spec discard_card(Game.join_code(), Player.id(), Card.t()) ::
          :ok | :needs_to_draw | :not_your_turn
  def discard_card(join_code, player_id, card) do
    GenServer.call(via(join_code), {:discard, {player_id, card}}, 5000)
  end

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
  def draw_card(join_code, player_id, source) do
    GenServer.call(via(join_code), {:draw, {player_id, source}}, 5000)
  end

  @doc """
  Returns whether or not a game with the specified join code exists.

  ## Examples

      iex> exists?("ABCD")
      true

      iex> exists?("ASDF")
      false
  """
  @spec exists?(Game.join_code()) :: boolean()
  def exists?(join_code) do
    case Horde.Registry.lookup(GameRegistry, join_code) do
      [] -> false
      _ -> true
    end
  end

  @doc """
  Returns whether or not the specified game is finished.

  ## Examples

      iex> finished?("ABCD")
      true
  """
  @spec finished?(Game.join_code()) :: boolean()
  def finished?(join_code) do
    GenServer.call(via(join_code), :finished?, 5000)
  end

  @doc """
  Returns the game with the specified join code.

  ## Examples

      iex> get("ABCD")
      %Game{}
  """
  @spec get(Game.join_code()) :: Game.t()
  def get(join_code) do
    GenServer.call(via(join_code), :get, 5000)
  end

  @doc """
  Get the player whose turn it currently is.

  ## Examples

      iex> get_current_turn("ABCD")
      %Player{id: "ffe6629a-faff-4053-b7b8-83c3a307400f", name: "Player 1"}
  """
  @spec get_current_turn(Game.join_code()) :: Player.t()
  def get_current_turn(join_code) do
    GenServer.call(via(join_code), :current_player, 5000)
  end

  @doc """
  Get the count of cards in each player's hand.

  ## Examples

      iex> get_hand_counts("ABCD")
      %{"179539f0-661e-4b56-ac67-fec916214223" => 10, "000cc69a-bb7d-4d3e-ae9f-e42e3dcac23e" => 3}
  """
  @spec get_hand_counts(Game.join_code()) :: %{optional(Player.id()) => non_neg_integer()}
  def get_hand_counts(join_code) do
    GenServer.call(via(join_code), :hand_counts, 5000)
  end

  @doc """
  Get the hand of the specified player.

  ## Examples

      iex> get_hand_for_player("ABCD", "557489d0-1ef2-4763-9b0b-d2ea3c80fd99")
      [%Card{color: :green, value: :twelve}, %Card{color: :blue, value: :nine}, ...]
  """
  @spec get_hand_for_player(Game.join_code(), Player.id()) :: list(Card.t())
  def get_hand_for_player(join_code, player_id) do
    GenServer.call(via(join_code), {:hand, player_id}, 5000)
  end

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
  def get_levels(join_code) do
    levels = GenServer.call(via(join_code), :levels, 5000)

    for {player_id, level_number} <- levels,
        into: %{},
        do: {player_id, Levels.by_number(level_number)}
  end

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
  def get_players(join_code) do
    GenServer.call(via(join_code), :players, 5000)
  end

  @doc """
  Gets the set of IDs of players who are ready for the next round to begin.
  """
  @spec get_players_ready(Game.join_code()) :: MapSet.t(Player.id())
  def get_players_ready(join_code) do
    GenServer.call(via(join_code), :players_ready, 5000)
  end

  @doc """
  Get the round number for the current round.
  """
  @spec get_round_number(Game.join_code()) :: non_neg_integer()
  def get_round_number(join_code) do
    GenServer.call(via(join_code), :current_round, 5000)
  end

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
  def get_scores(join_code) do
    GenServer.call(via(join_code), :scoring, 5000)
  end

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
  def get_table(join_code) do
    GenServer.call(via(join_code), :table, 5000)
  end

  @doc """
  Get the top card from the discard pile.

  ## Examples

      iex> get_top_discarded_card("ABCD")
      %Card{color: :green, value: :twelve}

      iex> get_top_discarded_card("ABCD")
      nil
  """
  @spec get_top_discarded_card(Game.join_code()) :: Card.t() | nil
  def get_top_discarded_card(join_code) do
    GenServer.call(via(join_code), :top_discarded_card, 5000)
  end

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
  def join_game(join_code, player_name) do
    player = Player.new(player_name)

    if exists?(join_code) do
      GenServer.call(via(join_code), {:join, player}, 5000)
    else
      :not_found
    end
  end

  @doc """
  Removes the specified player from the game. This is only allowed if the game
  is still in the lobby stage.

  If the player is currently alone in the game, the game will be deleted as
  well.
  """
  @spec leave_game(Game.join_code(), Player.id()) :: :ok | :already_started | :deleted
  def leave_game(join_code, player_id) do
    result = GenServer.call(via(join_code), {:delete_player, player_id}, 5000)
    with :empty_game <- result, do: delete_game(join_code)
  end

  @doc """
  Stores in the game state that the specified player is ready to move on to the
  next stage of the game.
  """
  @spec mark_player_ready(Game.join_code(), Player.id()) :: :ok
  def mark_player_ready(join_code, player_id) do
    result = GenServer.call(via(join_code), {:player_ready, player_id}, 5000)
    with :game_over <- result, do: delete_game(join_code)
  end

  @doc """
  Returns whether or not the specified player exists within the specified game.
  """
  @spec player_exists?(Game.t() | Game.join_code(), Player.id()) :: boolean()
  def player_exists?(join_code, player_id) when is_binary(join_code) do
    GenServer.call(via(join_code), {:player_exists?, player_id}, 5000)
  end

  def player_exists?(game, player_id), do: Game.player_exists?(game, player_id)

  @doc """
  Check whether or not the current round has started.

  ## Examples

      iex> round_started?("ABCD")
      true

      iex> round_started?("EFGH")
      false
  """
  @spec round_started?(Game.join_code()) :: boolean()
  def round_started?(join_code) do
    GenServer.call(via(join_code), :round_started?, 5000)
  end

  # Old School Agent Functions
  # TODO: Burn them all down :)

  @spec start_link({Game.join_code(), Player.t()}, GenServer.options()) :: on_start
  def start_link({join_code, player}, options \\ []) do
    GenServer.start_link(__MODULE__, {join_code, player}, options)
  end

  @spec get(agent, (state -> a), timeout) :: a when a: var
  def get(agent, fun, timeout \\ 5000) when is_function(fun, 1) do
    GenServer.call(agent, {:get, fun}, timeout)
  end

  @spec get(agent, module, atom, [term], timeout) :: any
  def get(agent, module, fun, args, timeout \\ 5000) do
    GenServer.call(agent, {:get, {module, fun, args}}, timeout)
  end

  @spec get_and_update(agent, (state -> {a, state}), timeout) :: a when a: var
  def get_and_update(agent, fun, timeout \\ 5000) when is_function(fun, 1) do
    GenServer.call(agent, {:get_and_update, fun}, timeout)
  end

  @spec get_and_update(agent, module, atom, [term], timeout) :: any
  def get_and_update(agent, module, fun, args, timeout \\ 5000) do
    GenServer.call(agent, {:get_and_update, {module, fun, args}}, timeout)
  end

  @spec update(agent, (state -> state), timeout) :: :ok
  def update(agent, fun, timeout \\ 5000) when is_function(fun, 1) do
    GenServer.call(agent, {:update, fun}, timeout)
  end

  @spec update(agent, module, atom, [term], timeout) :: :ok
  def update(agent, module, fun, args, timeout \\ 5000) do
    GenServer.call(agent, {:update, {module, fun, args}}, timeout)
  end

  @spec stop(agent, reason :: term, timeout) :: :ok
  def stop(agent, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(agent, reason, timeout)
  end

  # Server Functions (Internal Use Only)

  def init({join_code, player}) do
    Process.flag(:trap_exit, true)
    Process.put(:"$initial_call", {Game, :new, 2})

    game =
      case StateHandoff.pickup(join_code) do
        nil ->
          Logger.info("Creating new game #{join_code}")
          Game.new(join_code, player)

        game ->
          Logger.info("Creating game from state handoff #{join_code}")
          game
      end

    {:ok, game}
  end

  def handle_call({:add_to_table, {player_id, table_id, position, cards_to_add}}, _from, game) do
    case Game.add_to_table(game, player_id, table_id, position, cards_to_add) do
      {:ok, game} ->
        broadcast(game.join_code, :hand_counts_updated, Game.hand_counts(game))
        broadcast(game.join_code, :table_updated, game.table)

        {:reply, :ok, maybe_complete_round(game, player_id)}

      error ->
        {:reply, error, game}
    end
  end

  def handle_call(:creator, _from, game) do
    {:reply, Game.creator(game), game}
  end

  def handle_call(:current_player, _from, game) do
    {:reply, game.current_player, game}
  end

  def handle_call(:current_round, _from, game) do
    {:reply, game.current_round, game}
  end

  def handle_call(:current_turn_drawn?, _from, game) do
    {:reply, game.current_turn_drawn?, game}
  end

  def handle_call({:delete_player, player_id}, _from, game) do
    case Game.delete_player(game, player_id) do
      {:ok, game} ->
        broadcast(game.join_code, :players_updated, game.players)
        {:reply, :ok, game}

      error ->
        {:reply, error, game}
    end
  end

  def handle_call({:discard, {player_id, card}}, _from, game) do
    with ^player_id <- game.current_player.id,
         %Game{} = game <- Game.discard(game, card) do
      broadcast(game.join_code, :hand_counts_updated, Game.hand_counts(game))
      broadcast(game.join_code, :new_discard_top, card)

      if Game.round_finished?(game, player_id) do
        {:reply, :ok, maybe_complete_round(game, player_id)}
      else
        broadcast(game.join_code, :new_turn, game.current_player)
        {:reply, :ok, game}
      end
    else
      :needs_to_draw -> {:reply, :needs_to_draw, game}
      _ -> {:reply, :not_your_turn, game}
    end
  end

  def handle_call({:draw, {player_id, source}}, _from, game) do
    case Game.draw_card(game, player_id, source) do
      %Game{} = game ->
        if source == :discard_pile do
          broadcast(game.join_code, :new_discard_top, Game.top_discarded_card(game))
        end

        broadcast(game.join_code, :hand_counts_updated, Game.hand_counts(game))
        [new_card | _] = game.hands[player_id]

        {:reply, new_card, game}

      error ->
        IO.inspect(error)
        {:reply, error, game}
    end
  end

  def handle_call(:finished?, _from, game) do
    {:reply, game.current_stage == :finish, game}
  end

  def handle_call(:get, _from, game) do
    {:reply, game, game}
  end

  def handle_call({:get, fun}, _from, state) do
    {:reply, run(fun, [state]), state}
  end

  def handle_call({:get_and_update, fun}, _from, state) do
    case run(fun, [state]) do
      {reply, state} -> {:reply, reply, state}
      other -> {:stop, {:bad_return_value, other}, state}
    end
  end

  def handle_call(:hand_counts, _from, game) do
    {:reply, Game.hand_counts(game), game}
  end

  def handle_call({:hand, player_id}, _from, game) do
    {:reply, game.hands[player_id], game}
  end

  def handle_call({:join, player}, _from, game) do
    with {:ok, updated_game} <- Game.put_player(game, player),
         true <- length(updated_game.players) <= @max_players do
      broadcast(game.join_code, :players_updated, updated_game.players)
      {:reply, {:ok, player.id}, updated_game}
    else
      :already_started ->
        {:reply, :already_started, game}

      _ ->
        {:reply, :full, game}
    end
  end

  def handle_call(:levels, _from, game) do
    {:reply, game.levels, game}
  end

  def handle_call({:player_exists?, player_id}, _from, game) do
    {:reply, Game.player_exists?(game, player_id), game}
  end

  def handle_call(:players, _from, game) do
    {:reply, game.players, game}
  end

  # TODO: Move to cast
  def handle_call({:player_ready, player_id}, _from, game) do
    with {:all_ready, game} <- Game.mark_player_ready(game, player_id),
         {:ok, game} <- Game.start_round(game) do
      broadcast(game.join_code, :round_started, nil)
      {:reply, :ok, game}
    else
      :game_over ->
        {:reply, :game_over, game}

      {:ok, game} ->
        broadcast(game.join_code, :players_ready, game.players_ready)
        {:reply, :ok, game}
    end
  end

  def handle_call(:players_ready, _from, game) do
    {:reply, game.players_ready, game}
  end

  def handle_call(:round_started?, _from, game) do
    {:reply, game.current_stage == :play, game}
  end

  def handle_call(:scoring, _from, game) do
    {:reply, game.scoring, game}
  end

  def handle_call(:table, _from, game) do
    {:reply, game.table, game}
  end

  def handle_call(:top_discarded_card, _from, game) do
    card = Game.top_discarded_card(game)
    {:reply, card, game}
  end

  def handle_call({:update, fun}, _from, state) do
    {:reply, :ok, run(fun, [state])}
  end

  def handle_cast({:cast, fun}, state) do
    {:noreply, run(fun, [state])}
  end

  def code_change(_old, state, fun) do
    {:ok, run(fun, [state])}
  end

  defp run({m, f, a}, extra), do: apply(m, f, extra ++ a)
  defp run(fun, extra), do: apply(fun, extra)

  def handle_info({:EXIT, _pid, {:name_conflict, _, _, _}}, game), do: {:stop, :shutdown, game}

  def handle_info(message, %{join_code: join_code} = game) do
    Logger.warn("Game server #{join_code} received unexpected message: #{inspect(message)}")
    {:noreply, game}
  end

  # Matches whenever we manually stop a server since we don't need to move that
  # state to a new node
  def terminate(:normal, _game), do: :ok

  # Called when a SIGTERM is received to begin the handoff process for moving
  # game state to other nodes
  def terminate(_reason, %{join_code: join_code} = game) do
    StateHandoff.handoff(join_code, game)
    Process.sleep(10)
    :ok
  end

  # Private Functions

  @spec broadcast(Game.join_code(), event_type(), term()) :: :ok | {:error, term()}
  def broadcast(join_code, event_type, event) do
    Phoenix.PubSub.broadcast(Level10.PubSub, "game:" <> join_code, {event_type, event})
  end

  @spec broadcast_game_complete(Game.t(), Player.id()) :: :ok | {:error, term()}
  defp broadcast_game_complete(game, player_id) do
    player = Enum.find(game.players, &(&1.id == player_id))
    broadcast(game.join_code, :game_finished, player)
  end

  @spec broadcast_round_complete(Game.t(), Player.id()) :: Game.t()
  defp broadcast_round_complete(game, player_id) do
    player = Enum.find(game.players, &(&1.id == player_id))
    broadcast(game.join_code, :round_finished, player)
  end

  @spec maybe_complete_round(Game.t(), Player.id()) :: Game.t()
  defp maybe_complete_round(game, player_id) do
    with true <- Game.round_finished?(game, player_id),
         %{current_stage: :finish} = game <- Game.complete_round(game) do
      broadcast_game_complete(game, player_id)
      game
    else
      false ->
        game

      game ->
        broadcast_round_complete(game, player_id)
        game
    end
  end

  @spec via(Game.join_code()) :: game_name()
  defp via(join_code) do
    {:via, Horde.Registry, {GameRegistry, join_code}}
  end
end

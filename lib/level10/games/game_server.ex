defmodule Level10.Games.GameServer do
  @moduledoc """
  A server for holding game state
  """

  use GenServer
  alias Level10.StateHandoff
  alias Level10.Games.{Game, GameRegistry, Player}
  require Logger

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

  def handle_call({:get, fun}, _from, state) do
    {:reply, run(fun, [state]), state}
  end

  def handle_call({:get_and_update, fun}, _from, state) do
    case run(fun, [state]) do
      {reply, state} -> {:reply, reply, state}
      other -> {:stop, {:bad_return_value, other}, state}
    end
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

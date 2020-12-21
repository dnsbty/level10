defmodule Level10.Games.GameServer do
  @moduledoc """
  This module contains the logic for the servers that store the state of each
  game.

  Each server is initialized with an empty Game struct, and then messages sent
  to the server will either read from that struct or manipulate it in different
  ways.

  This module should handle only the most basic logic, while
  `Level10.Games.Game` will contain the logic for manipulating the game state.
  """

  use GenServer
  alias Level10.StateHandoff
  alias Level10.Games.{Card, Game, Player}
  require Logger

  @typedoc "Return values of `start*` functions"
  @type on_start :: {:ok, pid} | {:error, {:already_started, pid} | term}

  @typep event_type :: atom()

  @max_players 6

  @spec start_link({Game.join_code(), Player.t()}, GenServer.options()) :: on_start
  def start_link({join_code, player}, options \\ []) do
    GenServer.start_link(__MODULE__, {join_code, player}, options)
  end

  @impl true
  def init({join_code, player}) do
    Process.flag(:trap_exit, true)
    Process.put(:"$initial_call", {Game, :new, 2})

    {:ok, {join_code, player}, {:continue, :load_state}}
  end

  @impl true
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
        broadcast(game.join_code, :current_turn_drawn?, true)
        [new_card | _] = game.hands[player_id]

        {:reply, new_card, game}

      error ->
        {:reply, error, game}
    end
  end

  def handle_call(:finished?, _from, game) do
    {:reply, game.current_stage == :finish, game}
  end

  def handle_call(:get, _from, game) do
    {:reply, game, game}
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

  def handle_call({:next_player, player_id}, _from, game) do
    {:reply, Game.next_player(game, player_id), game}
  end

  def handle_call({:player_exists?, player_id}, _from, game) do
    {:reply, Game.player_exists?(game, player_id), game}
  end

  def handle_call(:players, _from, game) do
    {:reply, game.players, game}
  end

  def handle_call(:players_ready, _from, game) do
    {:reply, game.players_ready, game}
  end

  def handle_call(:remaining_players, _from, game) do
    {:reply, game.remaining_players, game}
  end

  def handle_call(:round_started?, _from, game) do
    {:reply, game.current_stage == :play, game}
  end

  def handle_call(:round_winner, _from, game) do
    {:reply, Game.round_winner(game), game}
  end

  def handle_call(:scoring, _from, game) do
    {:reply, game.scoring, game}
  end

  def handle_call({:skip_player, {player_id, player_to_skip}}, _from, game) do
    skip_card = Card.new(:skip)

    with ^player_id <- game.current_player.id,
         %Game{} = game <- Game.skip_player(game, player_to_skip),
         %Game{} = game <- Game.discard(game, skip_card) do
      broadcast(game.join_code, :hand_counts_updated, Game.hand_counts(game))
      broadcast(game.join_code, :new_discard_top, skip_card)
      broadcast(game.join_code, :player_skipped, player_to_skip)

      if Game.round_finished?(game, player_id) do
        {:reply, :ok, maybe_complete_round(game, player_id)}
      else
        broadcast(game.join_code, :new_turn, game.current_player)
        {:reply, :ok, game}
      end
    else
      :already_skipped -> {:reply, :already_skipped, game}
      :needs_to_draw -> {:reply, :needs_to_draw, game}
      _ -> {:reply, :not_your_turn, game}
    end
  end

  def handle_call(:skipped_players, _from, game) do
    {:reply, game.skipped_players, game}
  end

  def handle_call(:started?, _from, game) do
    {:reply, game.current_stage != :lobby, game}
  end

  def handle_call(:table, _from, game) do
    {:reply, game.table, game}
  end

  def handle_call({:table_cards, {player_id, player_table}}, _from, game) do
    case Game.set_player_table(game, player_id, player_table) do
      %Game{} = game ->
        broadcast(game.join_code, :hand_counts_updated, Game.hand_counts(game))
        broadcast(game.join_code, :table_updated, game.table)

        {:reply, :ok, maybe_complete_round(game, player_id)}

      error ->
        {:reply, error, game}
    end
  end

  def handle_call(:top_discarded_card, _from, game) do
    card = Game.top_discarded_card(game)
    {:reply, card, game}
  end

  @impl true
  def handle_cast({:player_ready, player_id}, game) do
    with {:all_ready, game} <- Game.mark_player_ready(game, player_id),
         {:ok, game} <- Game.start_round(game) do
      broadcast(game.join_code, :round_started, nil)
      {:noreply, game}
    else
      :game_over ->
        {:noreply, game}

      {:ok, game} ->
        broadcast(game.join_code, :players_ready, game.players_ready)
        {:noreply, game}
    end
  end

  def handle_cast({:remove_player, player_id}, game) do
    game = Game.remove_player(game, player_id)

    with status when status != :finish <- game.current_stage,
         true <- Game.all_ready?(game),
         {:ok, game} <- Game.start_round(game) do
      broadcast(game.join_code, :round_started, nil)
      {:noreply, game}
    else
      false ->
        broadcast(game.join_code, :player_removed, player_id)
        {:noreply, game}

      :finish ->
        broadcast(game.join_code, :player_removed, player_id)
        broadcast(game.join_code, :game_finished, nil)
        {:noreply, game}

      :game_over ->
        {:noreply, game}
    end
  end

  def handle_cast(:start_game, game) do
    case Game.start_game(game) do
      {:ok, game} ->
        Logger.info("Started game #{game.join_code}")
        broadcast(game.join_code, :game_started, nil)
        {:noreply, game}

      :single_player ->
        broadcast(game.join_code, :start_error, :single_player)
        {:noreply, game}
    end
  end

  def handle_cast({:update, fun}, state) do
    {:noreply, apply(fun, [state])}
  end

  @impl true
  def handle_continue(:load_state, {join_code, player}) do
    game =
      case StateHandoff.pickup(join_code) do
        nil ->
          Logger.info("Creating new game #{join_code}")
          Game.new(join_code, player)

        game ->
          Logger.info("Creating game from state handoff #{join_code}")
          game
      end

    {:noreply, game}
  end

  # Handle exits whenever a name conflict occurs
  @impl true
  def handle_info({:EXIT, _pid, {:name_conflict, _, _, _}}, game), do: {:stop, :shutdown, game}
  def handle_info({:EXIT, _pid, :shutdown}, game), do: {:noreply, game}

  # Matches whenever we manually stop a server since we don't need to move that
  # state to a new node
  @impl true
  def terminate(:normal, _game), do: :ok

  # Called when a SIGTERM is received to begin the handoff process for moving
  # game state to other nodes
  def terminate(_reason, game = %{join_code: join_code}) do
    StateHandoff.handoff(join_code, game)
    Process.sleep(10)
    :ok
  end

  # Private Functions

  @spec broadcast(Game.join_code(), event_type(), term()) :: :ok | {:error, term()}
  defp broadcast(join_code, event_type, event) do
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
end

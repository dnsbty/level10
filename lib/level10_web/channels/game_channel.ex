defmodule Level10Web.GameChannel do
  @moduledoc false
  use Level10Web, :channel
  alias Level10.Games
  alias Level10.Games.Game
  alias Level10.Games.Settings
  require Logger

  def join("game:lobby", _params, socket) do
    {:ok, socket}
  end

  def join("game:" <> join_code, params, socket) do
    case Games.connect(join_code, socket.assigns.user_id) do
      :ok ->
        send(self(), :after_join)
        {:ok, assign(socket, :join_code, join_code)}

      :game_not_found ->
        {:error, %{reason: "Game not found"}}

      :player_not_found ->
        user = %{id: socket.assigns.user_id, name: Map.get(params, "displayName", "")}

        case Games.join_game(join_code, user) do
          :ok ->
            Logger.info(["Joined game ", join_code])
            send(self(), :after_join)
            {:ok, assign(socket, :join_code, join_code)}

          :already_started ->
            {:error, %{reason: "Game has already started"}}

          :full ->
            {:error, %{reason: "Game is full"}}

          :not_found ->
            {:error, "Game not found"}
        end
    end
  end

  def handle_in("create_game", params, socket) do
    user = %{id: socket.assigns.user_id, name: Map.get(params, "displayName", "")}
    settings = %Settings{skip_next_player: Map.get(params, "skipNextPlayer", false)}

    case Games.create_game(user, settings) do
      {:ok, join_code} ->
        {:reply, {:ok, %{"joinCode" => join_code}}, socket}

      :error ->
        {:reply, {:error, "Failed to create game"}, socket}
    end
  end

  def handle_in("leave_game", _params, socket) do
    %{join_code: join_code, user_id: user_id} = socket.assigns

    case Games.delete_player(join_code, user_id) do
      :ok ->
        Logger.info(["Left game ", join_code])
        {:stop, :normal, socket}

      :already_started ->
        {:reply, {:error, "Game has already started"}, socket}
    end
  end

  def handle_in("start_game", _params, socket) do
    %{is_creator: is_creator, join_code: join_code} = socket.assigns

    if is_creator do
      Logger.info("Starting game #{join_code}")
      Games.start_game(join_code)
    else
      Logger.warn("Non-creator tried to start game #{join_code}")
    end

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    %{join_code: join_code, user_id: user_id} = socket.assigns
    Games.subscribe(join_code, user_id, socket)
    game = Games.get(join_code)

    presence = Games.list_presence(join_code)
    push(socket, "presence_state", presence)

    is_creator = Games.creator(join_code).id == user_id

    case game.current_stage do
      :lobby ->
        push(socket, "players_updated", %{players: game.players})

      :play ->
        state = %{
          current_player: game.current_player.id,
          discard_top: List.first(game.discard_pile),
          hand: game.hands[user_id],
          hand_counts: Game.hand_counts(game),
          levels: Games.format_levels(game.levels),
          players: game.players
        }

        push(socket, "latest_state", state)

      other ->
        # TODO: Implement after-join for finish and score states
        Logger.warn("After-join hasn't been implemented for stage #{other}")
    end

    {:noreply, assign(socket, is_creator: is_creator, players: game.players)}
  end

  def handle_info({:game_started, _}, socket) do
    %{join_code: join_code, user_id: user_id} = socket.assigns
    game = Games.get(join_code)

    state = %{
      current_player: game.current_player.id,
      discard_top: List.first(game.discard_pile),
      hand: game.hands[user_id],
      levels: Games.format_levels(game.levels),
      players: game.players
    }

    push(socket, "game_started", state)
    {:noreply, socket}
  end

  def handle_info({:hand_counts_updated, hand_counts}, socket) do
    push(socket, "hand_counts_updated", %{hand_counts: hand_counts})
    {:noreply, socket}
  end

  def handle_info({:new_discard_top, card}, socket) do
    push(socket, "new_discard_top", %{discard_top: card})
    {:noreply, socket}
  end

  def handle_info({:players_updated, players}, socket) do
    push(socket, "players_updated", %{players: players})
    {:noreply, socket}
  end

  def handle_out("presence_diff", diff, socket) do
    push(socket, "presence_diff", diff)
    {:noreply, socket}
  end
end

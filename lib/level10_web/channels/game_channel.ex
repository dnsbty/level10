defmodule Level10Web.GameChannel do
  @moduledoc false
  use Level10Web, :channel
  alias Level10.Games
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

  def handle_info(:after_join, socket) do
    %{join_code: join_code, user_id: user_id} = socket.assigns
    Games.subscribe(join_code, user_id, socket)

    players = Games.get_players(join_code)
    push(socket, "players_updated", %{players: players})

    presence = Games.list_presence(join_code)
    push(socket, "presence_state", presence)

    {:noreply, assign(socket, :players, players)}
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

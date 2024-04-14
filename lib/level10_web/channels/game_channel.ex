defmodule Level10Web.GameChannel do
  @moduledoc false
  use Level10Web, :channel
  alias Level10.Games
  alias Level10.Games.Card
  alias Level10.Games.Game
  alias Level10.Games.Levels
  alias Level10.Games.Player
  alias Level10.Games.Settings
  require Logger

  @type state :: %{
          current_player: String.t(),
          discard_top: Card.t() | nil,
          game_over: boolean,
          hand: Game.cards(),
          hand_counts: Game.hand_counts(),
          has_drawn: boolean,
          levels: %{optional(Player.t()) => Levels.level()},
          players: [Player.t()],
          players_ready: MapSet.t(),
          remaining_players: MapSet.t(),
          round_number: pos_integer,
          round_winner: Player.t() | nil,
          scores: [%{player_id: String.t(), level: pos_integer, points: pos_integer}],
          settings: Settings.t(),
          table: %{String.t() => map}
        }

  def join("game:lobby", _params, socket) do
    with :ok <- check_app_version(socket.assigns.app_version) do
      Logger.metadata(player_id: socket.assigns.player_id)
      {:ok, socket}
    end
  end

  def join("game:" <> join_code, params, socket) do
    player_id = socket.assigns.player_id

    case Games.connect(join_code, player_id) do
      :ok ->
        Logger.metadata(game_id: join_code, player_id: socket.assigns.player_id)
        send(self(), :after_join)
        {:ok, assign(socket, :join_code, join_code)}

      :game_not_found ->
        {:error, :not_found}

      :player_not_found ->
        player = %Player{
          id: player_id,
          name: Map.get(params, "display_name", "")
        }

        case Games.join_game(join_code, player) do
          :ok ->
            Logger.metadata(game_id: join_code, player_id: player_id)
            Logger.info(["Joined game ", join_code])
            send(self(), :after_join)
            {:ok, assign(socket, :join_code, join_code)}

          :already_started ->
            {:error, :already_started}

          :full ->
            {:error, :full}

          :not_found ->
            {:error, :not_found}
        end
    end
  end

  # Handle incoming messages from the websocket

  def handle_in("add_to_table", params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns

    with %{"cards" => cards, "player_id" => table_id, "position" => position} <- params,
         cards <- Enum.map(cards, &Card.from_json/1),
         :ok <- Games.add_to_table(join_code, player_id, table_id, position, cards) do
      {:reply, :ok, socket}
    else
      :invalid_group -> {:reply, {:error, :invalid_group}, socket}
      :level_incomplete -> {:reply, {:error, :level_incomplete}, socket}
      :needs_to_draw -> {:reply, {:error, :needs_to_draw}, socket}
      :not_your_turn -> {:reply, {:error, :not_your_turn}, socket}
      _ -> {:reply, {:error, :bad_request}, socket}
    end
  end

  def handle_in("create_game", params, socket) do
    %{player_id: player_id} = socket.assigns

    player = %Player{
      id: player_id,
      name: Map.get(params, "display_name", "")
    }

    settings = %Settings{
      skip_next_player: get_in(params, ["settings", "skip_next_player"]) || false
    }

    case Games.create_game(player, settings) do
      {:ok, join_code} ->
        {:reply, {:ok, %{"joinCode" => join_code}}, socket}

      :error ->
        {:reply, {:error, :server_error}, socket}
    end
  end

  def handle_in("discard", %{"card" => card} = params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns

    with %Card{} = card <- Card.from_json(card),
         :ok <- discard(card, socket.assigns, params) do
      hand = Games.get_hand_for_player(join_code, player_id)
      {:reply, {:ok, %{hand: hand}}, socket}
    else
      nil ->
        {:reply, {:error, :no_card}, socket}

      :already_skipped ->
        {:reply, {:error, :already_skipped}, socket}

      :choose_skip_target ->
        {:reply, {:error, :choose_skip_target}, socket}

      :invalid_stage ->
        {:reply, {:error, :invalid_stage}, socket}

      :not_your_turn ->
        {:reply, {:error, :not_your_turn}, socket}

      :needs_to_draw ->
        {:reply, {:error, :needs_to_draw}, socket}
    end
  end

  def handle_in("draw_card", %{"source" => source}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    source = atomic_source(source)

    case Games.draw_card(join_code, player_id, source) do
      %Card{} = new_card ->
        {:reply, {:ok, %{card: new_card}}, socket}

      error ->
        {:reply, {:error, error}, socket}
    end
  end

  def handle_in("leave_lobby", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns

    case Games.delete_player(join_code, player_id) do
      :ok ->
        Logger.info(["Left game ", join_code])
        {:stop, :normal, socket}

      :already_started ->
        {:reply, {:error, :already_started}, socket}
    end
  end

  def handle_in("leave_game", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.remove_player(join_code, player_id)
    Logger.info(["Left game ", join_code])
    {:stop, :normal, socket}
  end

  def handle_in("mark_ready", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.mark_player_ready(join_code, player_id)
    {:noreply, socket}
  end

  def handle_in("put_device_token", %{"token" => device_token}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.put_device_token(join_code, player_id, device_token)
    {:noreply, socket}
  end

  def handle_in("start_game", _params, socket) do
    %{is_creator: is_creator, join_code: join_code} = socket.assigns

    if is_creator do
      Logger.info("Starting game #{join_code}")
      Games.start_game(join_code)
    else
      Logger.warning("Non-creator tried to start game #{join_code}")
    end

    {:noreply, socket}
  end

  def handle_in("table_cards", %{"table" => table}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns

    table =
      table
      |> Enum.with_index(fn group, index -> {index, Enum.map(group, &Card.from_json/1)} end)
      |> Enum.into(%{})

    case Games.table_cards(join_code, player_id, table) do
      :ok ->
        {:reply, :ok, socket}

      :invalid_level ->
        {:reply, {:error, :invalid_level}, socket}

      error ->
        Logger.error("Error tabling cards: #{error}")
        {:reply, {:error, :bad_request}, socket}
    end
  end

  # Handle incoming messages from PubSub and other things

  # Ignoring this with the dialyzer because for some reason it thinks
  # current_state/2 will always return nil
  @dialyzer {:no_match, handle_info: 2}
  def handle_info(:after_join, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.subscribe(socket, player_id)
    game = Games.get(join_code)

    presence = Games.list_presence(join_code)
    push(socket, "presence_state", presence)

    is_creator = Games.creator(join_code).id == player_id

    skip_next_player = game.settings.skip_next_player || Game.remaining_player_count(game) < 3

    device_token = socket.assigns[:device_token]
    if device_token, do: Games.put_device_token(join_code, player_id, device_token)

    case current_state(game, player_id) do
      nil ->
        # This means the game is currently in the lobby stage, so only player
        # list updates are needed
        push(socket, "players_updated", %{players: game.players})

      state ->
        push(socket, "latest_state", state)
    end

    assigns = %{is_creator: is_creator, players: game.players, skip_next_player: skip_next_player}
    {:noreply, assign(socket, assigns)}
  end

  def handle_info({:current_turn_drawn?, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:game_finished, winner}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    game = Games.get(join_code)
    scores = Games.format_scores(game.scoring)
    player = Enum.find(game.players, &(&1.id == player_id))
    push(socket, "game_finished", %{round_winner: winner || player, scores: scores})
    {:noreply, socket}
  end

  def handle_info({:game_started, _}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    game = Games.get(join_code)
    skip_next_player = game.settings.skip_next_player || MapSet.size(game.remaining_players) < 3

    state = %{
      current_player: game.current_player.id,
      discard_top: List.first(game.discard_pile),
      hand: game.hands[player_id],
      levels: Games.format_levels(game.levels),
      players: game.players,
      settings: %{
        skip_next_player: skip_next_player
      }
    }

    push(socket, "game_started", state)
    {:noreply, assign(socket, skip_next_player: skip_next_player)}
  end

  def handle_info({:hand_counts_updated, hand_counts}, socket) do
    push(socket, "hand_counts_updated", %{hand_counts: hand_counts})
    {:noreply, socket}
  end

  def handle_info({:new_discard_top, card}, socket) do
    push(socket, "new_discard_top", %{discard_top: card})
    {:noreply, socket}
  end

  def handle_info({:new_turn, player}, socket) do
    push(socket, "new_turn", %{player: player.id})
    {:noreply, socket}
  end

  def handle_info({:players_ready, players_ready}, socket) do
    push(socket, "players_ready", %{players: players_ready})
    {:noreply, socket}
  end

  def handle_info({:player_removed, player_id}, socket) do
    push(socket, "player_removed", %{player: player_id})
    {:noreply, socket}
  end

  def handle_info({:players_updated, players}, socket) do
    push(socket, "players_updated", %{players: players})
    {:noreply, socket}
  end

  def handle_info(:put_device_token, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    device_token = socket.assigns[:device_token]
    if device_token, do: Games.put_device_token(join_code, player_id, device_token)
    {:noreply, socket}
  end

  def handle_info({:round_finished, winner}, socket) do
    game = Games.get(socket.assigns.join_code)
    scores = Games.format_scores(game.scoring)
    push(socket, "round_finished", %{scores: scores, winner: winner})
    {:noreply, socket}
  end

  def handle_info({:round_started, _}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    game = Games.get(join_code)
    skip_next_player = game.settings.skip_next_player || MapSet.size(game.remaining_players) < 3

    state = %{
      current_player: game.current_player.id,
      discard_top: List.first(game.discard_pile),
      hand: game.hands[player_id],
      hand_counts: Game.hand_counts(game),
      levels: Games.format_levels(game.levels),
      remaining_players: game.remaining_players,
      round_number: game.current_round,
      settings: %{
        skip_next_player: skip_next_player
      }
    }

    push(socket, "round_started", state)

    assigns = %{skip_next_player: skip_next_player}
    {:noreply, assign(socket, assigns)}
  end

  def handle_info({:skipped_players_updated, skipped_players}, socket) do
    push(socket, "skipped_players_updated", %{skipped_players: skipped_players})
    {:noreply, socket}
  end

  def handle_info({:table_updated, table}, socket) do
    push(socket, "table_updated", %{table: Games.format_table(table)})
    {:noreply, socket}
  end

  def handle_info(message, socket) do
    Logger.warning("Game channel received unrecognized message: #{inspect(message)}")
    {:noreply, socket}
  end

  # Private

  @spec atomic_source(String.t()) :: :draw_pile | :discard_pile
  defp atomic_source("draw_pile"), do: :draw_pile
  defp atomic_source("discard_pile"), do: :discard_pile

  @spec check_app_version(String.t()) :: :ok | {:error, :update_required}
  defp check_app_version(app_version) do
    min_version = Application.get_env(:level10, :app_min_version)

    case compare_versions(app_version, min_version) do
      :lt -> {:error, :update_required}
      _ -> :ok
    end
  end

  @spec compare_versions(String.t(), String.t()) :: :eq | :gt | :lt | :invalid
  defp compare_versions(first, second) do
    with {first_major, first_minor} <- parse_version(first),
         {second_major, second_minor} <- parse_version(second) do
      cond do
        first_major > second_major -> :gt
        first_major < second_major -> :lt
        first_minor > second_minor -> :gt
        first_minor < second_minor -> :lt
        true -> :eq
      end
    end
  end

  @spec discard(Card.t(), map(), map()) ::
          :ok
          | :already_skipped
          | :choose_skip_target
          | :invalid_stage
          | :not_your_turn
          | :needs_to_draw
  defp discard(%{value: :skip}, assigns, params) do
    %{join_code: join_code, skip_next_player: skip_next, player_id: player_id} = assigns

    cond do
      skip_next ->
        next_player = Games.get_next_player(join_code, player_id)
        Games.skip_player(join_code, player_id, next_player.id)

      params["player_to_skip"] == nil ->
        :choose_skip_target

      true ->
        Games.skip_player(join_code, player_id, params["player_to_skip"])
    end
  end

  defp discard(card, assigns, _) do
    %{join_code: join_code, player_id: player_id} = assigns
    Games.discard_card(join_code, player_id, card)
  end

  @spec current_state(Game.t(), String.t()) :: state() | nil
  defp current_state(game, player_id) do
    skip_next_player = game.settings.skip_next_player || Game.remaining_player_count(game) < 3
    current_player_id = game.current_player.id
    has_drawn = current_player_id == player_id && game.current_turn_drawn?

    state = %{
      current_player: current_player_id,
      discard_top: List.first(game.discard_pile),
      game_over: false,
      hand: game.hands[player_id],
      hand_counts: Game.hand_counts(game),
      has_drawn: has_drawn,
      levels: Games.format_levels(game.levels),
      players: game.players,
      players_ready: MapSet.new(),
      remaining_players: game.remaining_players,
      round_number: game.current_round,
      round_winner: nil,
      scores: Games.format_scores(game.scoring),
      settings: %{
        skip_next_player: skip_next_player
      },
      skipped_players: game.skipped_players,
      table: Games.format_table(game.table)
    }

    case game.current_stage do
      :lobby ->
        nil

      :play ->
        state

      :score ->
        diff = %{
          has_drawn: false,
          players_ready: game.players_ready,
          round_winner: Game.round_winner(game)
        }

        Map.merge(state, diff)

      :finish ->
        diff = %{
          game_over: true,
          has_drawn: false,
          players_ready: game.players_ready,
          round_winner: Game.round_winner(game)
        }

        Map.merge(state, diff)
    end
  end

  @spec parse_version(String.t()) :: {integer, integer} | :invalid
  defp parse_version(version) do
    with true <- is_binary(version),
         [major, minor] <- String.split(version, "."),
         {major_int, ""} <- Integer.parse(major),
         {minor_int, ""} <- Integer.parse(minor) do
      {major_int, minor_int}
    else
      _ -> :invalid
    end
  end
end

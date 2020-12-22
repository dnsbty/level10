defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  require Logger

  alias Level10.Games
  alias Games.{Card, Levels}
  alias Level10Web.{Endpoint, GameView, ScoringLive}
  alias Level10Web.Router.Helpers, as: Routes

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with true <- Games.exists?(join_code),
         true <- Games.started?(join_code),
         true <- Games.player_exists?(join_code, player_id),
         remaining = Games.remaining_players(join_code),
         true <- MapSet.member?(remaining, player_id) do
      Games.subscribe(join_code, player_id)

      players = Games.get_players(join_code)
      hand = join_code |> Games.get_hand_for_player(player_id) |> Card.sort()
      levels = Games.get_levels(join_code)
      player_level = levels[player_id]
      table = Games.get_table(join_code)
      has_completed_level = !is_nil(table[player_id])
      player_table = Map.get(table, player_id, empty_player_table(player_level))
      discard_top = Games.get_top_discarded_card(join_code)
      turn = Games.get_current_turn(join_code)
      round_winner = Games.round_winner(join_code)
      hand_counts = Games.get_hand_counts(join_code)
      skipped_players = Games.get_skipped_players(join_code)
      next_player = Games.get_next_player(join_code, player_id)
      presence = Games.list_presence(join_code)
      settings = Games.get_settings(join_code)

      has_drawn =
        if turn.id == player_id, do: Games.current_player_has_drawn?(join_code), else: false

      assigns = [
        choose_skip_target: false,
        discard_top: discard_top,
        game_over: false,
        hand: hand,
        hand_counts: hand_counts,
        has_completed_level: has_completed_level,
        has_drawn_card: has_drawn,
        join_code: params["join_code"],
        levels: levels,
        next_player_id: next_player.id,
        player_id: params["player_id"],
        player_level: player_level,
        player_table: player_table,
        players: players,
        presence: presence,
        remaining_players: remaining,
        round_winner: round_winner,
        overflow_hidden: !is_nil(round_winner),
        selected_indexes: MapSet.new(),
        settings: settings,
        skipped_players: skipped_players,
        table: table,
        turn: turn
      ]

      {:ok, assign(socket, assigns)}
    else
      _ ->
        {:ok, push_redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    GameView.render("game.html", assigns)
  end

  # Handle events sent from the frontend

  def handle_event("add_to_table", %{"player_id" => table_id, "position" => position}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns

    with {position, ""} <- Integer.parse(position),
         [_ | _] = cards_to_add <- selected_cards(socket),
         :ok <- Games.add_to_table(join_code, player_id, table_id, position, cards_to_add) do
      hand = socket.assigns.hand -- cards_to_add
      {:noreply, assign(socket, hand: hand, selected_indexes: MapSet.new())}
    else
      [] ->
        {:noreply, socket}

      error ->
        message =
          case error do
            :invalid_group -> "Those cards don't match the group silly 😋"
            :level_incomplete -> "Finish up your own level before you worry about others 🤓"
            :needs_to_draw -> "You need to draw before you can do that 😂"
            :not_your_turn -> "Watch it bud! It's not your turn yet 😠"
            _ -> "I'm not sure what you just did, but I don't like it 🤨"
          end

        {:noreply, flash_error(socket, message)}
    end
  end

  def handle_event("cancel_skip", _, socket) do
    {:noreply, assign(socket, choose_skip_target: false, selected_indexes: MapSet.new())}
  end

  def handle_event("discard", params, socket) do
    with [position] <- MapSet.to_list(socket.assigns.selected_indexes),
         {card, hand} = List.pop_at(socket.assigns.hand, position),
         :ok <- discard(card, socket.assigns, params) do
      assigns = [choose_skip_target: false, hand: Card.sort(hand), selected_indexes: MapSet.new()]
      {:noreply, assign(socket, assigns)}
    else
      :choose_skip_target ->
        {:noreply, assign(socket, choose_skip_target: true)}

      [] ->
        message = "You need to select a card in your hand before you can discard it silly 😄"
        {:noreply, flash_error(socket, message)}

      [%Card{} | _] ->
        message = "Nice try, but you can only discard one card at a time 🧐"
        {:noreply, flash_error(socket, message)}

      {:already_skipped, player} ->
        message =
          "#{player.name} was already skipped... Continue that vendetta on your next turn instead 😈"

        {:noreply, flash_error(socket, message)}

      :not_your_turn ->
        message = "What are you up to? You can't discard when it's not your turn... 🕵️‍♂️"
        {:noreply, flash_error(socket, message)}

      :need_to_draw ->
        message = "You can't discard when you haven't drawn yet. Refresh the page and try again 🤓"
        {:noreply, flash_error(socket, message)}
    end
  end

  def handle_event("draw_card", %{"source" => source}, socket = %{assigns: assigns}) do
    player_id = assigns.player_id
    source = atomic_source(source)

    case Games.draw_card(assigns.join_code, player_id, source) do
      %Card{} = new_card ->
        {:noreply, assign(socket, hand: [new_card | assigns.hand], has_drawn_card: true)}

      error ->
        message =
          case error do
            :already_drawn -> "You can't draw twice in the same turn silly 😋"
            :empty_discard_pile -> "What are you trying to draw? The discard pile is empty... 🕵️‍♂️"
            :skip -> "You can't draw a skip that has already been discarded 😂"
            :not_your_turn -> "Watch it bud! It's not your turn yet 😠"
            _ -> "I'm not sure what you just did, but I don't like it 🤨"
          end

        {:noreply, flash_error(socket, message)}
    end
  end

  def handle_event("show_scores", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    path = Routes.live_path(Endpoint, ScoringLive, join_code, player_id: player_id)

    {:noreply, push_redirect(socket, to: path)}
  end

  def handle_event("table_cards", %{"position" => position}, socket = %{assigns: assigns}) do
    cards_to_table = selected_cards(socket)

    with {position, ""} <- Integer.parse(position),
         table_group when not is_nil(table_group) <- Enum.at(assigns.player_level, position),
         true <- Levels.valid_group?(table_group, cards_to_table) do
      hand = assigns.hand -- cards_to_table
      player_table = Map.put(assigns.player_table, position, cards_to_table)

      # don't send the new table to the server unless all of the groups have
      # cards in them
      has_completed_level =
        if Enum.any?(player_table, fn {_, value} -> is_nil(value) end) do
          false
        else
          Games.table_cards(assigns.join_code, assigns.player_id, player_table)
          true
        end

      assigns = %{
        hand: hand,
        has_completed_level: has_completed_level,
        selected_indexes: MapSet.new(),
        player_table: player_table
      }

      {:noreply, assign(socket, assigns)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("toggle_selected", %{"position" => position}, socket) do
    with true <- socket.assigns.has_drawn_card,
         {position, ""} <- Integer.parse(position) do
      {:noreply, toggle_selected(socket, position)}
    else
      _ -> {:noreply, socket}
    end
  end

  # Handle incoming messages from PubSub and other things

  def handle_info({:game_finished, winner}, socket) do
    {:noreply, assign(socket, game_over: true, round_winner: winner)}
  end

  def handle_info({:hand_counts_updated, hand_counts}, socket) do
    {:noreply, assign(socket, :hand_counts, hand_counts)}
  end

  def handle_info({:new_discard_top, card}, socket) do
    {:noreply, assign(socket, :discard_top, card)}
  end

  def handle_info({:new_turn, player}, socket) do
    {:noreply, assign(socket, has_drawn_card: false, turn: player)}
  end

  def handle_info({:round_finished, winner}, socket) do
    {:noreply, assign(socket, round_winner: winner)}
  end

  def handle_info({:skipped_players_updated, skipped_players}, socket) do
    {:noreply, assign(socket, skipped_players: skipped_players)}
  end

  def handle_info({:table_updated, table}, socket) do
    player_table = Map.get(table, socket.assigns.player_id, socket.assigns.player_table)
    {:noreply, assign(socket, player_table: player_table, table: table)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, presence: Games.list_presence(socket.assigns.join_code))}
  end

  def handle_info(event, socket) do
    Logger.warn(["Game socket received unknown event: ", inspect(event)])
    {:noreply, socket}
  end

  # Private Functions

  @spec discard(Card.t(), map(), map()) ::
          :ok
          | {:already_skipped, Player.t()}
          | :choose_skip_target
          | :not_your_turn
          | :needs_to_draw
  defp discard(%{value: :skip}, assigns, %{"player_id" => skip_target}) do
    %{
      settings: settings,
      join_code: join_code,
      player_id: player_id,
      next_player_id: next_player_id
    } = assigns

    skip_target = if settings.skip_next_player, do: next_player_id, else: skip_target

    if skip_target in assigns.skipped_players do
      player = Enum.find(assigns.players, &(&1.id == skip_target))
      {:already_skipped, player}
    else
      Games.skip_player(join_code, player_id, skip_target)
    end
  end

  defp discard(%{value: :skip}, assigns, _) do
    if assigns.settings.skip_next_player || MapSet.size(assigns.remaining_players) < 3 do
      Games.skip_player(assigns.join_code, assigns.player_id, assigns.next_player_id)
    else
      :choose_skip_target
    end
  end

  defp discard(card, assigns, _) do
    Games.discard_card(assigns.join_code, assigns.player_id, card)
  end

  @spec empty_player_table(Levels.level()) :: Game.player_table()
  defp empty_player_table(level) do
    for index <- 0..(length(level) - 1), into: %{}, do: {index, nil}
  end

  @spec flash_error(Socket.t(), String.t()) :: Socket.t()
  defp flash_error(socket, message) do
    put_flash(socket, :error, message)
  end

  @spec selected_cards(Socket.t()) :: Game.cards()
  defp selected_cards(%{assigns: %{hand: hand, selected_indexes: indexes}}) do
    indexes
    |> MapSet.to_list()
    |> Enum.map(&Enum.at(hand, &1))
  end

  @spec atomic_source(String.t()) :: :draw_pile | :discard_pile
  defp atomic_source("draw_pile"), do: :draw_pile
  defp atomic_source("discard_pile"), do: :discard_pile

  @spec toggle_selected(Socket.t(), non_neg_integer()) :: Socket.t()
  defp toggle_selected(socket = %{assigns: %{selected_indexes: indexes}}, position) do
    selected_indexes =
      if MapSet.member?(indexes, position) do
        MapSet.delete(indexes, position)
      else
        MapSet.put(indexes, position)
      end

    assign(socket, :selected_indexes, selected_indexes)
  end
end

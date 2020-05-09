defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10.Games
  alias Games.{Card, Levels}
  alias Level10Web.GameView

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with true <- Games.exists?(join_code),
         true <- Games.started?(join_code),
         true <- Games.player_exists?(join_code, player_id) do
      Games.subscribe(params["join_code"])
      players = Games.get_players(join_code)
      hand = join_code |> Games.get_hand_for_player(player_id) |> Card.sort()
      scores = Games.get_scores(join_code)
      levels = levels_from_scores(scores)
      player_level = levels[player_id]
      table = Games.get_table(join_code)
      player_table = Map.get(table, player_id, empty_player_table(player_level))
      discard_top = Games.get_top_discarded_card(join_code)
      turn = Games.get_current_turn(join_code)

      Games.subscribe(join_code)

      has_drawn =
        if turn.id == player_id, do: Games.current_player_has_drawn?(join_code), else: false

      assigns = [
        discard_top: discard_top,
        hand: hand,
        has_drawn_card: has_drawn,
        join_code: params["join_code"],
        levels: levels,
        player_id: params["player_id"],
        player_level: player_level,
        player_table: player_table,
        players: players,
        selected_indexes: MapSet.new(),
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
      {:noreply, assign(socket, hand: hand)}
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

  def handle_event("discard", _, socket) do
    with [position] <- MapSet.to_list(socket.assigns.selected_indexes),
         {card, hand} = List.pop_at(socket.assigns.hand, position),
         :ok <- Games.discard_card(socket.assigns.join_code, socket.assigns.player_id, card) do
      {:noreply, assign(socket, hand: Card.sort(hand), selected_indexes: MapSet.new())}
    else
      [] ->
        message = "You need to select a card in your hand before you can discard it silly 😄"
        {:noreply, flash_error(socket, message)}

      selected when is_list(selected) ->
        message = "Nice try, but you can only discard one card at a time 🧐"
        {:noreply, flash_error(socket, message)}

      :not_your_turn ->
        message = "What are you up to? You can't discard when it's not your turn... 🕵️‍♂️"
        {:noreply, flash_error(socket, message)}

      :need_to_draw ->
        message = "You can't discard when you haven't drawn yet. Refresh the page and try again 🤓"
        {:noreply, flash_error(socket, message)}
    end
  end

  def handle_event("draw_card", %{"source" => source}, %{assigns: assigns} = socket) do
    player_id = assigns.player_id

    source =
      case source do
        "draw_pile" -> :draw_pile
        "discard_pile" -> :discard_pile
      end

    with ^player_id <- assigns.turn.id,
         false <- assigns.has_drawn_card,
         %Card{} = new_card <- Games.draw_card(assigns.join_code, player_id, source) do
      {:noreply, assign(socket, hand: [new_card | assigns.hand], has_drawn_card: true)}
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("table_cards", %{"position" => position}, %{assigns: assigns} = socket) do
    cards_to_table = selected_cards(socket)

    with {position, ""} <- Integer.parse(position),
         table_group when not is_nil(table_group) <- Enum.at(assigns.player_level, position),
         true <- Levels.valid_group?(table_group, cards_to_table) do
      hand = assigns.hand -- cards_to_table
      player_table = Map.put(assigns.player_table, position, cards_to_table)

      unless Enum.any?(player_table, fn {_, value} -> is_nil(value) end) do
        Games.table_cards(assigns.join_code, assigns.player_id, player_table)
      end

      {:noreply,
       assign(socket, hand: hand, selected_indexes: MapSet.new(), player_table: player_table)}
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

  def handle_info({:new_discard_top, card}, socket) do
    {:noreply, assign(socket, :discard_top, card)}
  end

  def handle_info({:new_turn, player}, socket) do
    {:noreply, assign(socket, has_drawn_card: false, turn: player)}
  end

  def handle_info({:table_updated, table}, socket) do
    player_table = Map.get(table, socket.assigns.player_id, socket.assigns.player_table)
    {:noreply, assign(socket, player_table: player_table, table: table)}
  end

  # Private Functions

  @spec empty_player_table(Levels.level()) :: Game.player_table()
  defp empty_player_table(level) do
    for index <- 0..(length(level) - 1), into: %{}, do: {index, nil}
  end

  @spec flash_error(Socket.t(), String.t()) :: Socket.t()
  defp flash_error(socket, message) do
    put_flash(socket, :error, message)
  end

  @spec levels_from_scores(Games.scores()) :: %{optional(Player.id()) => Levels.level()}
  defp levels_from_scores(scores) do
    levels_list =
      Enum.map(scores, fn {player_id, {level_number, _}} ->
        level = Levels.by_number(level_number)
        {player_id, level}
      end)

    Enum.into(levels_list, %{})
  end

  @spec selected_cards(Socket.t()) :: Game.cards()
  defp selected_cards(%{assigns: %{hand: hand, selected_indexes: indexes}}) do
    indexes
    |> MapSet.to_list()
    |> Enum.map(&Enum.at(hand, &1))
  end

  @spec toggle_selected(Socket.t(), non_neg_integer()) :: Socket.t()
  defp toggle_selected(%{assigns: %{selected_indexes: indexes}} = socket, position) do
    selected_indexes =
      if MapSet.member?(indexes, position) do
        MapSet.delete(indexes, position)
      else
        MapSet.put(indexes, position)
      end

    assign(socket, :selected_indexes, selected_indexes)
  end
end

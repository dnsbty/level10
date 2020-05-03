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
        players: players,
        selected_indexes: MapSet.new(),
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
         %Card{} = new_card <- Games.draw_card(assigns.join_code, assigns.player_id, source) do
      {:noreply, assign(socket, hand: [new_card | assigns.hand], has_drawn_card: true)}
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("toggle_selected", %{"position" => position}, socket) do
    case Integer.parse(position) do
      {position, ""} ->
        {:noreply, toggle_selected(socket, position)}

      _ ->
        {:noreply, socket}
    end
  end

  # Handle incoming messages from PubSub and other things

  def handle_info({:new_discard_top, card}, socket) do
    {:noreply, assign(socket, :discard_top, card)}
  end

  def handle_info({:new_turn, player}, socket) do
    {:noreply, assign(socket, has_drawn_card: false, turn: player)}
  end

  # Private Functions

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

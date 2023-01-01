defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Level10Web, :live_view
  import Level10Web.LiveHelpers
  alias Level10.Games
  alias Level10.Games.Card
  alias Level10.Games.Game
  alias Level10.Games.Levels
  alias Level10Web.GameComponents
  require Logger

  @happy_emoji ~w(🎉 😄 😎 🤩 🤑 🔥)
  @sad_emoji ~w(💥 💩 😈 🥴 😧 😑 😡 🤬 😵 😩 😢 😭 😒 😔)

  def mount(params, session, socket) do
    socket = fetch_player(socket, session)

    with %{redirected: nil} <- socket,
         player_id = socket.assigns.player.id,
         %{"join_code" => join_code} <- params,
         true <- Games.exists?(join_code),
         game = Games.get_for_player(join_code, player_id),
         true <- Game.started?(game),
         true <- Game.player_exists?(game, player_id),
         true <- MapSet.member?(game.remaining_players, player_id) do
      Games.subscribe(join_code, player_id)
      turn = game.current_player
      has_drawn_card = if turn.id == player_id, do: game.current_turn_drawn?, else: false
      raw_hand = game.hands[player_id]
      [new_card | unsorted_hand] = if has_drawn_card, do: raw_hand, else: [nil | raw_hand]
      levels = parse_levels(game.levels)
      player_level = levels[player_id]
      table = game.table
      round_winner = Game.round_winner(game)

      assigns = [
        choose_skip_target: false,
        discard_top: Game.top_discarded_card(game),
        drawn_card: new_card,
        game_over: false,
        hand: Card.sort(unsorted_hand),
        hand_counts: game.hand_counts,
        has_completed_level: !is_nil(table[player_id]),
        has_drawn_card: has_drawn_card,
        join_code: params["join_code"],
        levels: levels,
        new_card: new_card,
        new_card_selected: false,
        next_player_id: Game.next_player(game, player_id).id,
        player_id: player_id,
        player_level: player_level,
        player_table: Map.get(table, player_id, empty_player_table(player_level)),
        players: game.players,
        presence: Games.list_presence(join_code),
        remaining_players: game.remaining_players,
        round_winner: round_winner,
        overflow_hidden: !is_nil(round_winner),
        selected_indexes: MapSet.new(),
        settings: game.settings,
        skipped_players: game.skipped_players,
        table: table,
        turn: turn
      ]

      {:ok, assign(socket, assigns)}
    else
      %{__struct__: Phoenix.LiveView.Socket} = socket -> {:ok, socket}
      _ -> {:ok, push_redirect(socket, to: "/")}
    end
  end

  # Handle events sent from the frontend

  def handle_event("add_to_table", %{"player_id" => table_id, "position" => position}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    {cards_to_add, hand, new_card} = pop_selected_cards(socket.assigns)

    with {position, ""} <- Integer.parse(position),
         :ok <- Games.add_to_table(join_code, player_id, table_id, position, cards_to_add) do
      assigns = [
        hand: Card.sort(hand),
        new_card: new_card,
        new_card_selected: false,
        selected_indexes: MapSet.new()
      ]

      {:noreply, assign(socket, assigns)}
    else
      :invalid_group ->
        {:noreply, flash_warning(socket, "Those cards don't match the group silly 😋")}

      :level_incomplete ->
        message = "Finish up your own level before you worry about others 🤓"
        {:noreply, flash_warning(socket, message)}

      :needs_to_draw ->
        {:noreply, flash_warning(socket, "You need to draw before you can do that 😂")}

      :not_your_turn ->
        {:noreply, flash_warning(socket, "Watch it bud! It's not your turn yet 😠")}

      [] ->
        {:noreply, socket}

      _ ->
        {:noreply, flash_warning(socket, "I'm not sure what you just did, but I don't like it 🤨")}
    end
  end

  def handle_event("cancel_skip", _, socket) do
    assigns = [
      choose_skip_target: false,
      new_card_selected: false,
      overflow_hidden: false,
      selected_indexes: MapSet.new()
    ]

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("discard", params, socket) do
    with {card, hand} <- pop_selected_card(socket.assigns),
         :ok <- discard(card, socket.assigns, params) do
      assigns = [
        choose_skip_target: false,
        hand: Card.sort(hand),
        new_card: nil,
        new_card_selected: nil,
        overflow_hidden: false,
        selected_indexes: MapSet.new()
      ]

      {:noreply, assign(socket, assigns)}
    else
      :choose_skip_target ->
        {:noreply, assign(socket, choose_skip_target: true, overflow_hidden: true)}

      :none_selected ->
        message = "You need to select a card in your hand before you can discard it silly 😄"
        {:noreply, flash_warning(socket, message)}

      :multiple_cards_selected ->
        message = "Nice try, but you can only discard one card at a time 🧐"
        {:noreply, flash_warning(socket, message)}

      {:already_skipped, player} ->
        message =
          "#{player.name} was already skipped... Continue that vendetta on your next turn instead 😈"

        {:noreply, flash_warning(socket, message)}

      :not_your_turn ->
        message = "What are you up to? You can't discard when it's not your turn... 🕵️‍♂️"
        {:noreply, flash_warning(socket, message)}

      :needs_to_draw ->
        message = "You can't discard when you haven't drawn yet. Refresh the page and try again 🤓"
        {:noreply, flash_warning(socket, message)}
    end
  end

  def handle_event("draw_card", %{"source" => source}, %{assigns: assigns} = socket) do
    player_id = assigns.player_id
    source = atomic_source(source)

    case Games.draw_card(assigns.join_code, player_id, source) do
      %Card{} = new_card ->
        {:noreply, assign(socket, drawn_card: new_card, has_drawn_card: true, new_card: new_card)}

      error ->
        message =
          case error do
            :already_drawn -> "You can't draw twice in the same turn silly 😋"
            :empty_discard_pile -> "What are you trying to draw? The discard pile is empty... 🕵️‍♂️"
            :skip -> "You can't draw a skip that has already been discarded 😂"
            :not_your_turn -> "Watch it bud! It's not your turn yet 😠"
            _ -> "I'm not sure what you just did, but I don't like it 🤨"
          end

        {:noreply, flash_warning(socket, message)}
    end
  end

  def handle_event("show_scores", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    {:noreply, push_redirect(socket, to: ~p"/scores/#{join_code}?player_id=#{player_id}")}
  end

  def handle_event("table_cards", %{"position" => position}, %{assigns: assigns} = socket) do
    {cards_to_table, hand, new_card} = pop_selected_cards(assigns)

    with {position, ""} <- Integer.parse(position),
         table_group when not is_nil(table_group) <- Enum.at(assigns.player_level, position),
         true <- Levels.valid_group?(table_group, cards_to_table) do
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
        hand: Card.sort(hand),
        has_completed_level: has_completed_level,
        new_card: new_card,
        new_card_selected: false,
        selected_indexes: MapSet.new(),
        player_table: player_table
      }

      {:noreply, assign(socket, assigns)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("toggle_selected", %{"position" => "new"}, socket) do
    if socket.assigns.has_drawn_card do
      {:noreply, assign(socket, new_card_selected: !socket.assigns.new_card_selected)}
    else
      {:noreply, socket}
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

  def handle_event("untable_cards", %{"position" => position}, %{assigns: assigns} = socket) do
    with {position, ""} <- Integer.parse(position),
         cards_in_group when not is_nil(cards_in_group) <- assigns.player_table[position] do
      {new_card, cards_for_hand} =
        pop_card(cards_in_group, assigns.drawn_card, assigns.drawn_card)

      hand =
        assigns.hand
        |> Enum.concat(cards_for_hand)
        |> Card.sort()

      assigns = %{
        hand: hand,
        new_card: new_card,
        new_card_selected: false,
        selected_indexes: MapSet.new(),
        player_table: Map.put(assigns.player_table, position, nil)
      }

      {:noreply, assign(socket, assigns)}
    else
      _ -> {:noreply, socket}
    end
  end

  # Handle incoming messages from PubSub and other things

  def handle_info({:current_turn_drawn?, _}, socket) do
    {:noreply, socket}
  end

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
    {:noreply, assign(socket, drawn_card: nil, has_drawn_card: false, turn: player)}
  end

  def handle_info({:players_ready, _}, socket) do
    {:noreply, socket}
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

  @spec atomic_source(String.t()) :: :draw_pile | :discard_pile
  defp atomic_source("draw_pile"), do: :draw_pile
  defp atomic_source("discard_pile"), do: :discard_pile

  @spec complete_emoji(Game.table(), Player.id()) :: String.t()
  defp complete_emoji(table, player_id) do
    case table[player_id] do
      nil -> Enum.random(@sad_emoji)
      _ -> Enum.random(@happy_emoji)
    end
  end

  @spec discard(Card.t(), map(), map()) ::
          :ok
          | {:already_skipped, Player.t()}
          | :choose_skip_target
          | :not_your_turn
          | :needs_to_draw
  defp discard(%{value: :skip}, assigns, %{"player-id" => skip_target}) do
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

  @spec discard_pile_action(boolean(), boolean()) :: String.t()
  defp discard_pile_action(is_player_turn, has_drawn_card)
  defp discard_pile_action(false, _), do: ""
  defp discard_pile_action(true, true), do: "discard"
  defp discard_pile_action(true, false), do: "draw_card"

  @spec empty_player_table(Levels.level()) :: Game.player_table()
  defp empty_player_table(level) do
    for index <- 0..(length(level) - 1), into: %{}, do: {index, nil}
  end

  @spec flash_warning(Socket.t(), String.t()) :: Socket.t()
  defp flash_warning(socket, message) do
    put_flash(socket, :warning, message)
  end

  @spec level_group_name(Levels.level()) :: String.t()
  defp level_group_name({:set, count}), do: "Set of #{count}"
  defp level_group_name({:run, count}), do: "Run of #{count}"
  defp level_group_name({:color, count}), do: "#{count} of one Color"

  @spec parse_levels(map) :: map
  defp parse_levels(levels) do
    for {player_id, level_number} <- levels,
        into: %{},
        do: {player_id, Levels.by_number(level_number)}
  end

  @spec pop_card(list(Card.t()), Card.t(), Card.t()) :: {Card.t() | nil, list(Card.t())}
  defp pop_card(cards, desired_card, default) do
    case Enum.find_index(cards, fn card -> card == desired_card end) do
      nil -> {default, cards}
      index -> List.pop_at(cards, index)
    end
  end

  @spec pop_selected_card(map) ::
          {Card.t(), list(Card.t())} | :multiple_cards_selected | :none_selected
  defp pop_selected_card(%{new_card_selected: true} = assigns) do
    case MapSet.size(assigns.selected_indexes) do
      0 -> {assigns.new_card, assigns.hand}
      _ -> :multiple_cards_selected
    end
  end

  defp pop_selected_card(assigns) do
    case MapSet.to_list(assigns.selected_indexes) do
      [] ->
        :none_selected

      [position] ->
        {card, hand} = List.pop_at(assigns.hand, position)
        hand = if assigns.new_card, do: [assigns.new_card | hand], else: hand
        {card, hand}

      _ ->
        :multiple_cards_selected
    end
  end

  @spec pop_selected_cards(map) ::
          {selected_cards :: list(Card.t()), hand :: list(Card.t()), new_card :: Card.t() | nil}
  def pop_selected_cards(assigns) do
    {_count, selected_cards, hand} =
      Enum.reduce(assigns.hand, {0, [], []}, fn card, {index, selected_cards, hand} ->
        if index in assigns.selected_indexes do
          {index + 1, [card | selected_cards], hand}
        else
          {index + 1, selected_cards, [card | hand]}
        end
      end)

    if assigns.new_card_selected do
      {[assigns.new_card | selected_cards], hand, nil}
    else
      {selected_cards, hand, assigns.new_card}
    end
  end

  @spec round_winner(Player.t(), Player.id()) :: String.t()
  defp round_winner(%{id: player_id}, player_id), do: "You"
  defp round_winner(%{name: name}, _), do: name

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

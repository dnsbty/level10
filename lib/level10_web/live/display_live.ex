defmodule Level10Web.DisplayLive do
  @moduledoc false

  use Level10Web, :verified_routes
  use Phoenix.LiveView, layout: {Level10Web.Layouts, :display}
  require Logger

  alias Level10.Games
  alias Games.{Game, Levels}
  alias Level10Web.DisplayComponents

  @impl true
  def mount(_params, _session, socket) do
    initial_state = %{game: nil, join_code: "", presence: nil, stage: :join}
    {:ok, assign(socket, initial_state)}
  end

  @impl true
  def handle_event("begin_observing", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/display/#{socket.assigns.join_code}")}
  end

  def handle_event("validate", %{"game" => info}, socket) do
    socket = assign(socket, join_code: String.upcase(info["join_code"] || ""))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:current_turn_drawn?, true}, socket) do
    {:noreply, assign(socket, game: %{socket.assigns.game | current_turn_drawn?: true})}
  end

  def handle_info({:game_finished, winner}, socket) do
    {:noreply, assign(socket, game_over: true, round_winner: winner)}
  end

  def handle_info({:game_started, _}, socket) do
    game = Games.get(socket.assigns.join_code)

    assigns = %{
      discard_top: Game.top_discarded_card(game),
      game: game,
      hand_counts: Game.hand_counts(game),
      levels: game.levels,
      stage: game.current_stage
    }

    {:noreply, assign(socket, assigns)}
  end

  def handle_info({:hand_counts_updated, hand_counts}, socket) do
    {:noreply, assign(socket, :hand_counts, hand_counts)}
  end

  def handle_info({:new_discard_top, card}, socket) do
    {:noreply, assign(socket, :discard_top, card)}
  end

  def handle_info({:new_turn, player}, socket) do
    updated_game = %{socket.assigns.game | current_turn_drawn?: false, current_player: player}
    {:noreply, assign(socket, game: updated_game)}
  end

  def handle_info({:players_ready, players_ready}, socket) do
    game = %{socket.assigns.game | players_ready: players_ready}
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:round_finished, winner}, socket) do
    game = Games.get(socket.assigns.game.join_code)
    players = Game.players_by_score(game)
    assigns = %{game: game, players: players, round_winner: winner, stage: game.current_stage}
    {:noreply, assign(socket, assigns)}
  end

  def handle_info({:round_started, _}, socket) do
    game = Games.get(socket.assigns.game.join_code)

    levels =
      for {player_id, level} <- game.levels,
          do: {player_id, Levels.by_number(level)},
          into: %{}

    {:noreply, assign(socket, game: game, levels: levels, stage: game.current_stage)}
  end

  def handle_info({:table_updated, table}, socket) do
    updated_game = %{socket.assigns.game | table: table}
    {:noreply, assign(socket, game: updated_game)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    presence = Games.list_presence(socket.assigns.game.join_code)
    {:noreply, assign(socket, presence: presence)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_params(%{"join_code" => join_code}, _url, socket) do
    Games.subscribe(join_code, :display)
    game = Games.get(join_code)

    assigns = %{
      game: game,
      players: game.players,
      presence: Games.list_presence(join_code),
      stage: game.current_stage
    }

    assigns =
      case game.current_stage do
        :lobby ->
          assigns

        :play ->
          levels =
            for {player_id, level} <- game.levels,
                do: {player_id, Levels.by_number(level)},
                into: %{}

          new = %{
            levels: levels,
            hand_counts: Game.hand_counts(game),
            discard_top: Game.top_discarded_card(game)
          }

          Map.merge(assigns, new)

        :score ->
          new = %{players: Game.players_by_score(game), round_winner: Game.round_winner(game)}
          Map.merge(assigns, new)
      end

    {:noreply, assign(socket, assigns)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    case assigns[:stage] do
      :join -> DisplayComponents.join(assigns)
      :lobby -> DisplayComponents.lobby(assigns)
      :play -> DisplayComponents.play(assigns)
      :score -> DisplayComponents.score(assigns)
    end
  end
end

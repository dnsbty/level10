defmodule Level10Web.ScoringLive do
  @moduledoc """
  LiveView for displaying scores between rounds and at the end of the game.
  """

  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}

  alias Level10.Games
  alias Games.{Game, Player}
  alias Level10Web.{Endpoint, GameLive, ScoringView}
  alias Level10Web.Router.Helpers, as: Routes

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with %Game{} = game <- Games.get(join_code),
         stage when stage in [:finish, :score] <- game.current_stage,
         true <- Games.player_exists?(game, player_id) do
      scores = game.scoring
      players = sort_players(game.players, scores)
      [leader | _] = players
      presence = Games.list_presence(join_code)

      Games.subscribe(join_code, player_id)

      assigns = %{
        finished: stage == :finished,
        join_code: join_code,
        leader: leader,
        players: players,
        player_id: player_id,
        players_ready: game.players_ready,
        presence: presence,
        round_number: game.current_round,
        scores: scores
      }

      {:ok, assign(socket, assigns)}
    else
      error when error in [nil, false] -> {:ok, push_redirect(socket, to: "/")}
      stage when stage in [:play, :lobby] -> {:ok, redirect_to_game(socket, join_code, player_id)}
    end
  end

  def render(assigns) do
    ScoringView.render("index.html", assigns)
  end

  def handle_event("mark_ready", _params, %{assigns: %{finished: true}} = socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.mark_player_ready(join_code, player_id)
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("mark_ready", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.mark_player_ready(join_code, player_id)
    {:noreply, socket}
  end

  def handle_info({:players_ready, players_ready}, socket) do
    {:noreply, assign(socket, players_ready: players_ready)}
  end

  def handle_info({:round_started, _}, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    {:noreply, redirect_to_game(socket, join_code, player_id)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, presence: Games.list_presence(socket.assigns.join_code))}
  end

  # Private

  @spec redirect_to_game(Socket.t(), Game.join_code(), Player.id()) :: Socket.t()
  defp redirect_to_game(socket, join_code, player_id) do
    path = Routes.live_path(Endpoint, GameLive, join_code, player_id: player_id)
    push_redirect(socket, to: path)
  end

  defp sort_players(players, scores) do
    Enum.sort(players, fn %{id: player1}, %{id: player2} ->
      {level1, score1} = scores[player1]
      {level2, score2} = scores[player2]

      cond do
        level1 > level2 -> true
        level1 < level2 -> false
        true -> score1 <= score2
      end
    end)
  end
end

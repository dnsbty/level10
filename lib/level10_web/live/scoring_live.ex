defmodule Level10Web.ScoringLive do
  @moduledoc """
  LiveView for displaying scores between rounds and at the end of the game.
  """

  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}

  alias Level10.Games
  alias Level10Web.{Endpoint, GameLive, ScoringView}
  alias Level10Web.Router.Helpers, as: Routes

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with true <- Games.exists?(join_code),
         true <- Games.started?(join_code),
         true <- Games.player_exists?(join_code, player_id) do
      Games.subscribe(join_code)
      scores = Games.get_scores(join_code)
      players = join_code |> Games.get_players() |> sort_players(scores)

      assigns = %{
        join_code: join_code,
        players: players,
        player_id: player_id,
        players_ready: Games.get_players_ready(join_code),
        scores: scores
      }

      {:ok, assign(socket, assigns)}
    end
  end

  def render(assigns) do
    ScoringView.render("index.html", assigns)
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
    path = Routes.live_path(Endpoint, GameLive, join_code, player_id: player_id)

    {:noreply, push_redirect(socket, to: path)}
  end

  # Private

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

defmodule Level10Web.ScoringLive do
  @moduledoc """
  LiveView for displaying scores between rounds and at the end of the game.
  """

  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  import Level10Web.LiveHelpers

  alias Level10.{Games, Games.Game}
  alias Level10Web.Router.Helpers, as: Routes
  alias Level10Web.ScoringView

  def mount(params, session, socket) do
    socket = fetch_user(socket, session)

    with %{redirected: nil} <- socket,
         player_id = socket.assigns.user.id,
         %{"join_code" => join_code} <- params,
         %Game{} = game <- Games.get(join_code),
         stage when stage in [:finish, :score] <- game.current_stage,
         true <- Games.player_exists?(game, player_id) do
      Games.subscribe(join_code, player_id)

      scores = game.scoring
      players = Game.players_by_score(game)
      [leader | _] = players
      presence = Games.list_presence(join_code)

      assigns = %{
        confirm_leave: false,
        finished: stage == :finish,
        join_code: join_code,
        leader: leader,
        players: players,
        player_id: player_id,
        players_ready: game.players_ready,
        presence: presence,
        remaining_players: game.remaining_players,
        round_number: game.current_round,
        scores: scores
      }

      {:ok, assign(socket, assigns)}
    else
      %{__struct__: Phoenix.LiveView.Socket} = socket -> {:ok, socket}
      stage when stage in [:play, :lobby] -> {:ok, redirect_to_game(socket, params["join_code"])}
      _ -> {:ok, push_redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    ScoringView.render("index.html", assigns)
  end

  def handle_event("cancel_leave", _params, socket) do
    {:noreply, assign(socket, confirm_leave: false)}
  end

  def handle_event("confirm_leave", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns

    with :ok <- Games.remove_player(join_code, player_id) do
      socket =
        socket
        |> assign(action: :none, join_code: "")
        |> push_redirect(to: "/")

      {:noreply, socket}
    end
  end

  def handle_event("leave_game", _params, socket) do
    {:noreply, assign(socket, confirm_leave: true)}
  end

  def handle_event("mark_ready", _params, socket = %{assigns: %{finished: true}}) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.mark_player_ready(join_code, player_id)
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("mark_ready", _params, socket) do
    %{join_code: join_code, player_id: player_id} = socket.assigns
    Games.mark_player_ready(join_code, player_id)
    {:noreply, socket}
  end

  def handle_info({:game_finished, _}, socket) do
    {:noreply, assign(socket, finished: true)}
  end

  def handle_info({:players_ready, players_ready}, socket) do
    {:noreply, assign(socket, players_ready: players_ready)}
  end

  def handle_info({:player_removed, player_id}, socket) do
    remaining = MapSet.delete(socket.assigns.remaining_players, player_id)
    {:noreply, assign(socket, remaining_players: remaining)}
  end

  def handle_info({:round_started, _}, socket) do
    {:noreply, redirect_to_game(socket, socket.assigns.join_code)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, presence: Games.list_presence(socket.assigns.join_code))}
  end

  # Private

  @spec redirect_to_game(Socket.t(), Game.join_code()) :: Socket.t()
  defp redirect_to_game(socket, join_code) do
    path = Routes.game_path(socket, :play, join_code)
    push_redirect(socket, to: path)
  end
end

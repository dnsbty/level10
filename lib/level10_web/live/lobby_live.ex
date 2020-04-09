defmodule Level10Web.LobbyLive do
  @moduledoc """
  This module handles the UI for allowing users to create or join a game, as
  well as see the users that are currently in the same game lobby.
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  require Logger

  alias Level10Web.Router.Helpers, as: Routes
  alias Level10Web.LobbyView
  alias Level10.Games

  def mount(_params, _session, socket) do
    initial_assigns = [
      action: :none,
      join_code: "",
      name: "",
      player_id: nil,
      players: [],
      is_creator: false
    ]

    {:ok, assign(socket, initial_assigns)}
  end

  def render(assigns) do
    LobbyView.render("#{assigns.action}.html", assigns)
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, action: :none)}
  end

  def handle_event("create_game", _params, %{assigns: %{action: :none}} = socket) do
    {:noreply, assign(socket, action: :create)}
  end

  def handle_event("create_game", _params, socket) do
    case Games.create_game(socket.assigns.name) do
      {:ok, join_code, player_id} ->
        Logger.info(["Created game ", join_code])
        Games.subscribe(join_code)
        players = Games.get_players(join_code)

        socket =
          assign(socket,
            action: :wait,
            is_creator: true,
            join_code: join_code,
            player_id: player_id,
            players: players
          )

        {:noreply, socket}

      :error ->
        socket =
          put_flash(
            socket,
            :error,
            "Something went wrong with our system and the game couldn't be created. Sorry we suck 😕"
          )

        {:noreply, socket}
    end
  end

  def handle_event("join_game", _params, %{assigns: %{action: :none}} = socket) do
    {:noreply, assign(socket, action: :join)}
  end

  def handle_event("join_game", _params, socket) do
    case Games.join_game(socket.assigns.join_code, socket.assigns.name) do
      {:ok, player_id} ->
        Logger.info(["Joined game ", socket.assigns.join_code])
        Games.subscribe(socket.assigns.join_code)
        players = Games.get_players(socket.assigns.join_code)

        {:noreply, assign(socket, action: :wait, player_id: player_id, players: players)}

      :not_found ->
        socket =
          put_flash(
            socket,
            :error,
            "That join code doesn't exist. Are you trying to hack us? 🤨"
          )

        {:noreply, socket}

      :already_started ->
        socket =
          put_flash(
            socket,
            :error,
            "The game you're trying to join has already started. Looks like you need some new friends 😬"
          )

        {:noreply, socket}
    end
  end

  def handle_event("leave", _params, socket) do
    case Games.leave_game(socket.assigns.join_code, socket.assigns.player_id) do
      :ok ->
        Logger.info(["Left game ", socket.assigns.join_code])
        Games.unsubscribe(socket.assigns.join_code)
        {:noreply, assign(socket, action: :none, join_code: "", name: "")}

      :already_started ->
        socket =
          put_flash(
            socket,
            :error,
            "The game has already started. Don't screw it up for everyone else! 😡"
          )

        {:noreply, socket}
    end
  end

  def handle_event("start_game", _params, %{assigns: %{is_creator: false}} = socket) do
    Logger.warn("Non-creator tried to start game #{socket.assigns.join_code}")
    {:noreply, socket}
  end

  def handle_event("start_game", _params, socket) do
    case Games.start_game(socket.assigns.join_code) do
      :single_player ->
        Logger.warn("User tried to start game #{socket.assigns.join_code} with no other players")

        socket =
          put_flash(
            socket,
            :error,
            "At least 2 players are needed to play Level 10. Time to make some friends! 😘"
          )

        {:noreply, socket}

      :ok ->
        Logger.info("Starting game #{socket.assigns.join_code}")
        {:noreply, assign(socket, starting: true)}
    end
  end

  def handle_event("validate", %{"info" => info}, socket) do
    socket = assign(socket, name: info["name"], join_code: String.upcase(info["join_code"] || ""))
    {:noreply, socket}
  end

  def handle_info({:game_started, _}, socket) do
    join_code = socket.assigns.join_code
    player_id = socket.assigns.player_id

    path =
      Routes.live_path(Level10Web.Endpoint, Level10Web.GameLive, join_code, player_id: player_id)

    {:noreply, push_redirect(socket, to: path)}
  end

  def handle_info({:players_updated, players}, socket) do
    {:noreply, assign(socket, :players, players)}
  end
end

defmodule Level10Web.LobbyLive do
  @moduledoc """
  This module handles the UI for allowing users to create or join a game, as
  well as see the users that are currently in the same game lobby.
  """

  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  require Logger
  import Level10Web.LiveHelpers

  alias Level10.Games
  alias Games.{Player, Settings}
  alias Level10Web.LobbyView
  alias Level10Web.Router.Helpers, as: Routes

  def mount(_params, session, socket) do
    socket = fetch_user(socket, session)
    IO.inspect(socket.assigns.user)

    initial_assigns = [
      is_creator: nil,
      join_code: "",
      display_name: socket.assigns.user.name,
      players: nil,
      presence: nil,
      settings: Settings.default(),
      show_menu: false
    ]

    {:ok, assign(socket, initial_assigns)}
  end

  def handle_params(_params, _url, socket = %{assigns: %{live_action: :none}}) do
    {:noreply, socket}
  end

  def handle_params(params, _url, socket = %{assigns: %{live_action: :wait}}) do
    with %{"join_code" => join_code} <- params do
      user_id = socket.assigns.user.id
      Games.subscribe(join_code, user_id)

      assigns = %{
        is_creator: socket.assigns.is_creator || Games.creator(join_code).id == user_id,
        join_code: join_code,
        players: socket.assigns.players || Games.get_players(join_code),
        presence: socket.assigns.presence || Games.list_presence(join_code)
      }

      {:noreply, assign(socket, assigns)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_params(params, _url, socket) do
    join_code = params["join_code"] || socket.assigns.join_code
    {:noreply, assign(socket, join_code: join_code)}
  end

  def render(assigns) do
    LobbyView.render("#{assigns.live_action}.html", assigns)
  end

  def handle_event("cancel", _params, socket) do
    socket =
      socket
      |> assign(join_code: "")
      |> push_patch(to: Routes.lobby_path(socket, :none))

    {:noreply, socket}
  end

  def handle_event("create_game", _params, socket) do
    %{display_name: display_name, settings: settings, user: user} = socket.assigns
    user = %{user | name: display_name}

    case Games.create_game(user, settings) do
      {:ok, join_code} ->
        players = [Player.new(user)]
        presence = Games.list_presence(join_code)
        Games.subscribe(join_code, user.id)
        new_url = Routes.lobby_path(socket, :wait, join_code)

        assigns = %{
          user: user,
          is_creator: true,
          join_code: join_code,
          players: players,
          presence: presence
        }

        socket =
          socket
          |> assign(assigns)
          |> push_patch(to: new_url)

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

  def handle_event("join_game", _params, socket) do
    %{display_name: display_name, join_code: join_code, user: user} = socket.assigns
    user = %{user | name: display_name}

    case Games.join_game(join_code, user) do
      :ok ->
        Logger.info(["Joined game ", join_code])

        players = Games.get_players(join_code)
        presence = Games.list_presence(join_code)
        Games.subscribe(join_code, user.id)
        new_url = Routes.lobby_path(socket, :wait, join_code)

        assigns = %{
          players: players,
          presence: presence
        }

        {:noreply, socket |> assign(assigns) |> push_patch(to: new_url)}

      error ->
        message =
          case error do
            :already_started ->
              "The game you're trying to join has already started. Looks like you need some new friends 😬"

            :full ->
              "That game is already full. Looks like you were the slow one in the group 😩"

            :not_found ->
              "That join code doesn't exist. Are you trying to hack us? 🤨"
          end

        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("leave", _params, socket) do
    %{join_code: join_code, user: user} = socket.assigns

    case Games.delete_player(join_code, user.id) do
      :ok ->
        Logger.info(["Left game ", join_code])
        Games.unsubscribe(join_code, user.id)

        socket =
          socket
          |> assign(join_code: "")
          |> push_patch(to: Routes.lobby_path(socket, :none))

        {:noreply, socket}

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

  def handle_event("start_game", _params, socket = %{assigns: %{is_creator: false}}) do
    Logger.warn("Non-creator tried to start game #{socket.assigns.join_code}")
    {:noreply, socket}
  end

  def handle_event("start_game", _params, socket) do
    Games.start_game(socket.assigns.join_code)
    {:noreply, assign(socket, starting: true)}
  end

  def handle_event("toggle_menu", _params, socket) do
    {:noreply, assign(socket, show_menu: !socket.assigns.show_menu)}
  end

  def handle_event("toggle_setting", %{"setting" => "skip_next_player"}, socket) do
    value = !socket.assigns.settings.skip_next_player
    settings = Settings.set(socket.assigns.settings, :skip_next_player, value)
    {:noreply, assign(socket, settings: settings)}
  end

  def handle_event("validate", %{"info" => info}, socket) do
    join_code = String.upcase(info["join_code"] || "")
    socket = assign(socket, display_name: info["display_name"], join_code: join_code)
    {:noreply, socket}
  end

  def handle_info({:game_started, _}, socket) do
    path = Routes.game_path(socket, :play, socket.assigns.join_code)

    {:noreply, push_redirect(socket, to: path)}
  end

  def handle_info({:players_updated, players}, socket) do
    creator = List.last(players)
    is_creator = creator.id == socket.assigns.user.id
    {:noreply, assign(socket, is_creator: is_creator, players: players)}
  end

  def handle_info({:start_error, error}, socket) do
    message =
      case error do
        :single_player ->
          "At least 2 players are needed to play Level 10. Time to make some friends! 😘"
      end

    socket = assign(socket, starting: false)
    {:noreply, put_flash(socket, :error, message)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, presence: Games.list_presence(socket.assigns.join_code))}
  end
end

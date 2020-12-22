defmodule Level10Web.LobbyLive do
  @moduledoc """
  This module handles the UI for allowing users to create or join a game, as
  well as see the users that are currently in the same game lobby.
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  require Logger

  alias Level10.Games
  alias Games.{Player, Settings}
  alias Level10Web.Router.Helpers, as: Routes
  alias Level10Web.LobbyView

  def mount(_params, _session, socket) do
    initial_assigns = [
      action: :none,
      is_creator: nil,
      join_code: "",
      name: "",
      player_id: nil,
      players: nil,
      presence: nil,
      settings: Settings.default()
    ]

    {:ok, assign(socket, initial_assigns)}
  end

  def handle_params(params = %{"action" => "wait"}, _url, socket) do
    with %{"join_code" => join_code, "player_id" => player_id} <- params do
      Games.subscribe(join_code, player_id)

      assigns = %{
        action: :wait,
        is_creator: socket.assigns.is_creator || Games.creator(join_code).id == player_id,
        join_code: join_code,
        player_id: player_id,
        players: socket.assigns.players || Games.get_players(join_code),
        presence: socket.assigns.presence || Games.list_presence(join_code)
      }

      {:noreply, assign(socket, assigns)}
    end
  end

  def handle_params(params, _url, socket) do
    assigns = %{
      action: action(params["action"]),
      join_code: params["join_code"] || socket.assigns.join_code,
      player_id: params["player_id"] || socket.assigns.player_id
    }

    {:noreply, assign(socket, assigns)}
  end

  def render(assigns) do
    LobbyView.render("#{assigns.action}.html", assigns)
  end

  def handle_event("cancel", _params, socket) do
    socket =
      socket
      |> assign(action: :none, join_code: "")
      |> push_patch(to: Routes.live_path(socket, __MODULE__, ""))

    {:noreply, socket}
  end

  def handle_event("create_game", _params, socket) do
    case Games.create_game(socket.assigns.name, socket.assigns.settings) do
      {:ok, join_code, player_id} ->
        players = [%Player{id: player_id, name: socket.assigns.name}]
        presence = Games.list_presence(join_code)
        Games.subscribe(join_code, player_id)
        new_url = Routes.live_path(socket, __MODULE__, "wait", join_code, player_id: player_id)

        assigns = %{
          action: :wait,
          is_creator: true,
          join_code: join_code,
          player_id: player_id,
          players: players,
          presence: presence
        }

        {:noreply, socket |> assign(assigns) |> push_patch(to: new_url)}

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
    %{join_code: join_code, name: name} = socket.assigns

    case Games.join_game(join_code, name) do
      {:ok, player_id} ->
        Logger.info(["Joined game ", join_code])

        players = Games.get_players(join_code)
        presence = Games.list_presence(join_code)
        Games.subscribe(join_code, player_id)
        new_url = Routes.live_path(socket, __MODULE__, "wait", join_code, player_id: player_id)

        assigns = %{
          action: :wait,
          player_id: player_id,
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
    %{join_code: join_code, player_id: player_id} = socket.assigns

    case Games.delete_player(join_code, player_id) do
      :ok ->
        Logger.info(["Left game ", join_code])
        Games.unsubscribe(join_code, player_id)

        socket =
          socket
          |> assign(action: :none, join_code: "")
          |> push_patch(to: Routes.live_path(socket, __MODULE__, ""))

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

  def handle_event("toggle_setting", %{"setting" => "skip_next_player"}, socket) do
    value = !socket.assigns.settings.skip_next_player
    settings = Settings.set(socket.assigns.settings, :skip_next_player, value)
    {:noreply, assign(socket, settings: settings)}
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
    creator = List.last(players)
    is_creator = creator.id == socket.assigns.player_id
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

  # Private

  @spec action(String.t() | nil) :: :create | :join | :none | :wait
  defp action("create"), do: :create
  defp action("join"), do: :join
  defp action("wait"), do: :wait
  defp action(_), do: :none
end

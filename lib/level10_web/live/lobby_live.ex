defmodule Level10Web.LobbyLive do
  @moduledoc """
  This module handles the UI for allowing users to create or join a game, as
  well as see the users that are currently in the same game lobby.
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10Web.LobbyView
  alias Level10.Games

  def mount(_params, _session, socket) do
    socket = assign(socket, action: :none, join_code: "", name: "", player_id: nil)
    {:ok, socket}
  end

  def render(assigns) do
    LobbyView.render("create_or_join.html", assigns)
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
        {:noreply, assign(socket, action: :wait, join_code: join_code, player_id: player_id)}

      :error ->
        {:noreply, assign(socket, error: "Game could not be created")}
    end
  end

  def handle_event("join_game", _params, %{assigns: %{action: :none}} = socket) do
    {:noreply, assign(socket, action: :join)}
  end

  def handle_event("join_game", _params, socket) do
    case Games.join_game(socket.assigns.join_code, socket.assigns.name) do
      {:ok, player_id} ->
        {:noreply, assign(socket, action: :wait, player_id: player_id)}

      :already_started ->
        {:noreply, assign(socket, error: "Game already started")}
    end
  end

  def handle_event("leave", _params, socket) do
    {:noreply, assign(socket, action: :none, join_code: "", name: "")}
  end

  def handle_event("validate", %{"info" => info}, socket) do
    socket = assign(socket, name: info["name"], join_code: info["join_code"])
    {:noreply, socket}
  end
end

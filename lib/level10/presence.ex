defmodule Level10.Presence do
  @moduledoc """
  Track the presence of users in games.
  """

  use Phoenix.Presence,
    otp_app: :level10,
    pubsub_server: Level10.PubSub

  alias Level10.Games.Game
  alias Level10.Games.Player

  @doc """
  Returns whether or not the specified user is currently connected to the
  server.
  """
  @spec player_connected?(Game.join_code(), Player.id()) :: boolean
  def player_connected?(join_code, player_id) do
    case get_by_key("game:" <> join_code, player_id) do
      [] -> false
      _ -> true
    end
  end

  @doc """
  Track the presence of a user within a game
  """
  @spec track_player(Phoenix.Socket.t() | Game.join_code(), Player.id()) ::
          {:ok, binary()} | {:error, term()}
  def track_player(%Phoenix.Socket{} = socket, player_id) do
    track(socket, player_id, %{})
  end

  def track_player(join_code, player_id) do
    track(self(), "game:" <> join_code, player_id, %{})
  end
end

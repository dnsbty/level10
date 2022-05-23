defmodule Level10.Presence do
  @moduledoc """
  Track the presence of users in games.
  """

  use Phoenix.Presence,
    otp_app: :level10,
    pubsub_server: Level10.PubSub

  alias Level10.Games.{Game, Player}

  @app_name "level10"

  @doc """
  Count all of the users present at a global level
  """
  @spec count :: non_neg_integer()
  def count, do: list() |> map_size()

  @doc """
  List all of the users present at a global level
  """
  @spec list :: Phoenix.Presence.presences()
  def list, do: list(@app_name)

  @doc """
  Track the presence of a user for use at a global level
  """
  @spec track_user(Player.id(), Game.join_code()) :: :ok | {:error, term()}
  def track_user(player_id, join_code \\ nil) do
    metadata = if is_nil(join_code), do: %{}, else: %{join_code: join_code}
    track(self(), @app_name, player_id, metadata)
  end

  @doc """
  Track the presence of a user within a game
  """
  @spec track_player(Phoenix.Socket.t() | Game.join_code(), Player.id()) ::
          {:ok, binary()} | {:error, term()}
  def track_player(socket = %Phoenix.Socket{}, player_id) do
    track(socket, player_id, %{})
  end

  def track_player(join_code, player_id) do
    track(self(), "game:" <> join_code, player_id, %{})
  end
end

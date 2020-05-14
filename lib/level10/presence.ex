defmodule Level10.Presence do
  @moduledoc """
  Track the presence of users in games.
  """

  use Phoenix.Presence,
    otp_app: :level10,
    pubsub_server: Level10.PubSub
end

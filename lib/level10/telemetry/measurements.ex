defmodule Level10.Telemetry.Measurements do
  @moduledoc """
  Defines measurements to be periodically taken and sent to telemetry
  """

  alias Level10.{Games, Presence}

  @spec dispatch_game_count() :: :ok
  def dispatch_game_count() do
    :telemetry.execute([:level10, :games], %{count: Games.count()}, %{})
  end

  @spec dispatch_user_count() :: :ok
  def dispatch_user_count do
    :telemetry.execute([:level10, :users], %{count: Presence.count()}, %{})
  end
end

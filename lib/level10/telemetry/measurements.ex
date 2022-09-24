defmodule Level10.Telemetry.Measurements do
  @moduledoc """
  Defines measurements to be periodically taken and sent to telemetry
  """

  alias Level10.Games
  alias Level10.StateHandoff

  @spec dispatch_game_count :: :ok
  def dispatch_game_count do
    :telemetry.execute([:level10, :games], %{count: Games.count()}, %{})
  end

  @spec dispatch_state_handoff_size :: :ok
  def dispatch_state_handoff_size do
    :telemetry.execute([:level10, :state_handoff], %{count: StateHandoff.size()}, %{})
  end

  @spec dispatch_user_count :: :ok
  def dispatch_user_count do
    :telemetry.execute([:level10, :users], %{count: Games.connected_player_count()}, %{})
  end
end

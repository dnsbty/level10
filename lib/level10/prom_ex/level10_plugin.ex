defmodule Level10.PromEx.Level10Plugin do
  @moduledoc """
  This plugin is responsible for defining metrics that should be sent to
  Prometheus specifically for the Level 10 application.
  """

  use PromEx.Plugin
  alias Level10.Games
  alias Level10.StateHandoff

  @impl true
  def event_metrics(_opts) do
    Event.build(
      :level10_event_metrics,
      [
        # State Handoff
        counter(
          [:level10, :prom_ex, :state_handoff, :added],
          event_name: [:level10, :state_handoff, :added],
          description: "The number of games that have been added to state handoff.",
          tag_values: fn %{join_code: join_code} -> %{join_code: join_code} end,
          tags: [:join_code]
        ),
        counter(
          [:level10, :prom_ex, :state_handoff, :temporary_pickup],
          event_name: [:level10, :state_handoff, :temporary_pickup],
          description:
            "The number of games that have been temporarily picked up from state handoff.",
          tag_values: fn %{join_code: join_code} -> %{join_code: join_code} end,
          tags: [:join_code]
        ),
        counter(
          [:level10, :prom_ex, :state_handoff, :pickup],
          event_name: [:level10, :state_handoff, :pickup],
          description: "The number of games that have been picked up from state handoff.",
          tag_values: fn %{join_code: join_code} -> %{join_code: join_code} end,
          tags: [:join_code]
        )
      ]
    )
  end

  @impl true
  def polling_metrics(opts) do
    Polling.build(
      :level10_polling_metrics,
      Keyword.get(opts, :poll_rate, 5_000),
      {__MODULE__, :execute_polling_metrics, []},
      [
        last_value(
          [:level10, :games, :count],
          event_name: [:prom_ex, :plugin, :level10, :games],
          description: "The total number of active games.",
          measurement: :count
        ),
        last_value(
          [:level10, :state_handoff, :count],
          event_name: [:prom_ex, :plugin, :level10, :state_handoff],
          description: "The total number of games in the state handoff CRDT.",
          measurement: :count
        ),
        last_value(
          [:level10, :users, :count],
          event_name: [:prom_ex, :plugin, :level10, :users],
          description: "The total number of connected users.",
          measurement: :count
        )
      ]
    )
  end

  @spec execute_polling_metrics :: no_return
  def execute_polling_metrics do
    dispatch_game_count()
    dispatch_state_handoff_size()
    dispatch_user_count()
  end

  # Private

  @spec dispatch_game_count :: :ok
  defp dispatch_game_count do
    count = Games.count()
    :telemetry.execute([:prom_ex, :plugin, :level10, :games], %{count: count}, %{})
  end

  @spec dispatch_state_handoff_size :: :ok
  defp dispatch_state_handoff_size do
    size = StateHandoff.size()
    :telemetry.execute([:prom_ex, :plugin, :level10, :state_handoff], %{count: size}, %{})
  end

  @spec dispatch_user_count :: :ok
  defp dispatch_user_count do
    count = Games.connected_player_count()
    :telemetry.execute([:prom_ex, :plugin, :level10, :users], %{count: count}, %{})
  end
end

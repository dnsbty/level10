defmodule Level10.Telemetry do
  @moduledoc """
  Handles the telemetry metrics for the application.

  Each of the measurements in `periodic_measurements/0` will be polled every 10
  seconds.

  Each of the metrics in `metrics/0` will be received as well, and displayed on
  the live dashboard.
  """

  use Supervisor
  import Telemetry.Metrics
  alias Level10.Telemetry.Measurements

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Game Metrics
      summary("level10.games.count"),
      summary("level10.users.count"),
      summary("level10.state_handoff.count"),

      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      {Measurements, :dispatch_game_count, []},
      {Measurements, :dispatch_user_count, []},
      {Measurements, :dispatch_state_handoff_size, []}
    ]
  end
end

defmodule Level10.PromEx do
  @moduledoc """
  Handles publishing metrics for Prometheus to scrape.
  """

  use PromEx, otp_app: :level10

  # alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      # Plugins.Application,
      # Plugins.Beam,
      # {Plugins.Phoenix, router: Level10Web.Router, endpoint: Level10Web.Endpoint},
      # Plugins.PhoenixLiveView,

      # Custom plugins
      Level10.PromEx.Level10Plugin
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus_on_fly",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "phoenix_live_view.json"}

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:level10, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end

defmodule Level10.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Level10.Games.GameSupervisor},
      {Registry, keys: :unique, name: Level10.Games.GameRegistry},
      {Phoenix.PubSub, name: Level10.PubSub},
      Level10.Presence,
      Level10.Telemetry,
      Level10Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Level10.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Level10Web.Endpoint.config_change(changed, removed)
    :ok
  end
end

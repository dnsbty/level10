defmodule Level10.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = [
      level10: [
        strategy: Cluster.Strategy.Kubernetes,
        config: [
          kubernetes_selector: System.get_env("LIBCLUSTER_KUBERNETES_SELECTOR", "level10"),
          kubernetes_node_basename:
            System.get_env("LIBCLUSTER_KUBERNETES_NODE_BASENAME", "level10")
        ]
      ]
    ]

    children = [
      {Horde.Registry, name: Level10.Games.GameRegistry, keys: :unique, members: :auto},
      {Horde.DynamicSupervisor,
       [name: Level10.Games.GameSupervisor, strategy: :one_for_one, members: :auto]},
      {Cluster.Supervisor, [topologies, [name: Level10.ClusterSupervisor]]},
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

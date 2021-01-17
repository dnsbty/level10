defmodule Level10.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:level10, :cluster_topologies, [])

    children = [
      Level10.StateHandoff,
      {Horde.DynamicSupervisor,
       [
         name: Level10.Games.GameSupervisor,
         shutdown: 5000,
         strategy: :one_for_one,
         members: :auto
       ]},
      {Horde.Registry, name: Level10.Games.GameRegistry, keys: :unique, members: :auto},
      {Cluster.Supervisor, [topologies, [name: Level10.ClusterSupervisor]]},
      Level10.Repo,
      {Phoenix.PubSub, name: Level10.PubSub},
      Level10.Presence,
      Level10.Telemetry,
      Level10.TerminationMonitor,
      Level10Web.Endpoint
    ]

    children =
      if Application.get_env(:level10, :database_only, false) do
        [Level10.Repo]
      else
        children
      end

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

import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :level10, Level10Web.Endpoint,
    http: [
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base

  config :level10, Level10Web.Endpoint, server: true

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  # Configure clustering
  config :level10,
    cluster_topologies: [
      level10: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]
end

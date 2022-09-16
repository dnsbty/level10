import Config

key = System.get_env("APNS_KEY")
key_identifier = System.get_env("APNS_KEY_ID")
team_id = System.get_env("APNS_TEAM_ID")

case config_env() do
  :prod ->
    secret_key_base = 'bCIa/PcHlRstP+RwqTtHRgqQwVF97SeHa2GXL0UEOh3IRBLayk6QpomaGICfTCPM'

    config :level10, Level10Web.Endpoint,
      http: [
        transport_options: [socket_opts: [:inet6]]
      ],
      secret_key_base: secret_key_base

    config :level10, Level10Web.Endpoint, server: true

    app_name = System.get_env("FLY_APP_NAME") || raise "FLY_APP_NAME not available"

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

    # Configure push notifications
    if is_nil(key), do: raise("environment variable APNS_KEY is missing.")
    if is_nil(key_identifier), do: raise("environment variable APNS_KEY_ID is missing.")
    if is_nil(team_id), do: raise("environment variable APNS_TEAM_ID is missing.")

    config :level10, Level10.PushNotifications.APNS,
      adapter: Pigeon.APNS,
      key: key,
      key_identifier: key_identifier,
      mode: :prod,
      team_id: team_id

    admin_username =
      System.get_env("ADMIN_USERNAME") ||
        raise """
        environment variable ADMIN_USERNAME is missing.
        """

    admin_password =
      System.get_env("ADMIN_PASSWORD") ||
        raise """
        environment variable ADMIN_PASSWORD is missing.
        """

    # Replace default credentials for the live dashboard
    config :level10,
      admin_credentials: [
        username: admin_username,
        password: admin_password
      ]

  :dev ->
    disabled = is_nil(key) || is_nil(key_identifier) || is_nil(team_id)

    config :level10, Level10.PushNotifications.APNS,
      adapter: Pigeon.APNS,
      disabled?: disabled,
      key: key,
      key_identifier: key_identifier,
      mode: :dev,
      team_id: team_id

  :test ->
    config :level10, Level10.PushNotifications.APNS, disabled?: true
end

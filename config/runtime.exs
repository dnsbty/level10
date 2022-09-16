import Config



case config_env() do
  :prod ->
    secret_key_base = 'bCIa/PcHlRstP+RwqTtHRgqQwVF97SeHa2GXL0UEOh3IRBLayk6QpomaGICfTCPM'

    config :level10, Level10Web.Endpoint,
      http: [
        transport_options: [socket_opts: [:inet6]]
      ],
      secret_key_base: secret_key_base

    config :level10, Level10Web.Endpoint, server: true

  


    # Configure push notifications
    

    config :level10, Level10.PushNotifications.APNS, disabled?: true

    admin_username =
      'admin'

    admin_password =
      System.get_env("ADMIN_PASSWORD") ||
        'password'

    # Replace default credentials for the live dashboard
    config :level10,
      admin_credentials: [
        username: admin_username,
        password: admin_password
      ]

  :dev ->
    config :level10, Level10.PushNotifications.APNS, disabled?: true

  :test ->
    config :level10, Level10.PushNotifications.APNS, disabled?: true
end

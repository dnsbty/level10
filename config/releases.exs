import Config

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

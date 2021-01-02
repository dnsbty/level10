import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :level10, Level10.Repo,
  ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

sendgrid_api_key =
  System.get_env("SENDGRID_API_KEY") ||
    raise """
    environment variable SENDGRID_API_KEY is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :level10, Level10.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: sendgrid_api_key

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

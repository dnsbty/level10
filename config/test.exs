use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :level10, Level10.Repo,
  username: "postgres",
  password: "postgres",
  database: "level10_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :level10, Level10Web.Endpoint,
  http: [port: 4002],
  server: false

# Use Bamboo's test adapter for testing sent emails
config :level10, Level10.Mailer, adapter: Bamboo.TestAdapter
config :level10, include_sent_email_route?: true

# Print only warnings and errors during test
config :logger, level: :warn

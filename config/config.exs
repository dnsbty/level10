# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :level10,
  ecto_repos: [Level10.Repo]

# Configures the endpoint
config :level10, Level10Web.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4000")],
  url: [host: "localhost"],
  secret_key_base: "/zVsH2ul2vyeKjwK7OVZI8dJM7bnN8DqwXb8N8Oy3Cw+KscU88U/oB4JXeBPWM+t",
  render_errors: [view: Level10Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Level10.PubSub,
  live_view: [signing_salt: "HjUnOT+E"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:game_id, :player_id, :request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

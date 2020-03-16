# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :level10, Level10Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/zVsH2ul2vyeKjwK7OVZI8dJM7bnN8DqwXb8N8Oy3Cw+KscU88U/oB4JXeBPWM+t",
  render_errors: [view: Level10Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Level10.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "HjUnOT+E"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

import Config

config :level10, Level10Web.Endpoint,
  url: [port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

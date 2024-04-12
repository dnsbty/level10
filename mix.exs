defmodule Level10.MixProject do
  use Mix.Project

  def project do
    [
      app: :level10,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Level10.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp releases do
    [
      level10: [
        include_executables_for: [:unix]
      ]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:delta_crdt, "~> 0.6.3"},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      # Fixes a compilation issue with Ecto <- Etso <- Logflare
      {:ecto, "~> 3.10", override: true},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:finch, "~> 0.14", override: true},
      {:gettext, "~> 0.18"},
      {:hackney, "~> 1.20"},
      {:heroicons, "~> 0.5"},
      {:horde, "~> 0.9.0"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.2"},
      {:logflare_logger_backend, "~> 0.11.0"},
      {:phoenix, "~> 1.7-rc.0", override: true},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:pigeon, "~> 2.0.0-rc.0"},
      {:prom_ex, "~> 1.9"},
      {:plug_cowboy, "~> 2.6", override: true},
      {:sentry, "~> 10.3"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:telemetry, "~> 1.0", override: true},
      # Need override because prom_ex 1.9 requires version 0.6
      {:telemetry_metrics, "~> 1.0", override: true},
      {:telemetry_poller, "~> 1.0", override: true},
      {:uinta, "~> 0.9"}
    ]
  end

  defp aliases do
    [
      compile: "compile --warnings-as-errors",
      setup: ["deps.get", "cmd --cd assets npm install"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end

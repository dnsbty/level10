defmodule Level10.MixProject do
  use Mix.Project

  def project do
    [
      app: :level10,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:gettext, "~> 0.18"},
      {:horde, "~> 0.8.4"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.2"},
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.5"},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:telemetry, "~> 1.0", override: true},
      {:telemetry_metrics, "~> 0.6"},
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

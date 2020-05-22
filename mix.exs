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

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ecto, "~> 3.4"},
      {:gettext, "~> 0.11"},
      {:horde, "~> 0.8.0-rc.1"},
      {:jason, "~> 1.0"},
      {:libcluster, "~> 3.2"},
      {:phoenix, "~> 1.5"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.13"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.2"},
      {:telemetry_metrics, "~> 0.5"},
      {:telemetry_poller, "~> 0.5", override: true}
    ]
  end
end

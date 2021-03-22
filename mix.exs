defmodule Recognizer.MixProject do
  use Mix.Project

  def project do
    [
      app: :recognizer,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Recognizer.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:appsignal_phoenix, "~> 2.0.4"},
      {:argon2_elixir, "~> 2.0"},
      {:bottle, github: "system76/bottle", ref: "b3b78b6"},
      {:cors_plug, "~> 2.0"},
      {:cowboy, "~> 2.8", override: true},
      {:cowlib, "~> 2.9.1", override: true},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:decorator, "~> 1.2"},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.4"},
      {:eqrcode, "~> 0.1.7"},
      {:ex_machina, "~> 2.4", only: :test},
      {:ex_aws_sqs, "~> 3.2"},
      {:ex_aws, "~> 2.0"},
      {:ex_oauth2_provider, "~> 0.5.6"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 2.1"},
      {:httpoison, "~> 0.13"},
      {:jason, "~> 1.0"},
      {:logger_json, github: "Nebo15/logger_json", ref: "8e4290a"},
      {:myxql, ">= 0.0.0"},
      {:redix, ">= 0.0.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix, "~> 1.5.7"},
      {:phx_gen_auth, "~> 0.6", only: [:dev], runtime: false},
      {:plug_cowboy, "~> 2.4"},
      {:pot, "~> 1.0"},
      {:saxy, "~> 1.1"},
      {:spandex, "~> 3.0.3"},
      {:spandex_datadog, "~> 1.1.0"},
      {:spandex_ecto, "~> 0.6.2"},
      {:spandex_phoenix, "~> 1.0.5"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:ueberauth_github, "~> 0.8"},
      {:ueberauth_google, "~> 0.10"},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm ci --prefix assets"],
      "ecto.seed": ["run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

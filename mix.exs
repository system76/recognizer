defmodule Recognizer.MixProject do
  use Mix.Project

  def project do
    [
      app: :recognizer,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
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
      mod: {Recognizer.Application, []}
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
      {:argon2_elixir, "~> 2.0"},
      {:bottle, github: "system76/bottle", ref: "1a49e7bc7d8f7bf556c5780b70e9eb60a06a8ca7"},
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
      {:hammer, "~> 6.0"},
      {:hammer_backend_redis, "~> 6.1"},
      {:hammer_plug, "~> 3.0"},
      {:httpoison, "~> 1.8.2"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.6.0"},
      {:logger_json, github: "Nebo15/logger_json", ref: "8e4290a"},
      {:myxql, ">= 0.0.0"},
      {:redix, ">= 0.0.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_html_helpers, "~> 1.0.1"},
      {:phoenix_view, "~> 2.0.3"},
      {:phoenix, "~> 1.7.1"},
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
      "ecto.legacy_migrate": ["ecto.migrate --migrations-path priv/repo/_legacy_migrations"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end

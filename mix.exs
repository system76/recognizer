defmodule Recognizer.MixProject do
  use Mix.Project

  def project do
    [
      app: :recognizer,
      version: "0.1.0",
      elixir: "~> 1.17.3",
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
      {:argon2_elixir, "~> 4.1.2"},
      {:bottle, github: "system76/bottle", ref: "465b429c7b341eb92dcfb7f210170a1e5265da41"},
      {:cors_plug, "~> 3.0.3"},
      # {:cowboy, "~> 2.12.0", override: true},
      {:cowlib, "~> 2.13.0", override: true},
      {:credo, "~> 1.7.11", only: [:dev, :test], runtime: false},
      {:decorator, "~> 1.4.0"},
      {:ecto_enum, "~> 1.4"},
      {:ecto_sql, "~> 3.1"},
      {:eqrcode, "~> 0.2.0"},
      {:ex_machina, "~> 2.8", only: :test},
      {:ex_aws_sqs, "~> 3.4"},
      {:ex_aws, "~> 2.5.8"},
      {:ex_oauth2_provider, "~> 0.5.7"},
      {:gettext, "~> 0.26.2"},
      {:guardian, "~> 2.0"},
      {:guardian_db, "~> 2.0"},
      {:hammer, "~> 6.2.1"},
      {:hammer_backend_redis, "~> 6.2"},
      {:hammer_plug, "~> 3.2"},
      {:httpoison, "~> 2.2.1"},
      {:jason, "~> 1.4.4"},
      {:joken, "~> 2.6.2"},
      {:logger_json, "~> 5.1.2"},
      # {:logger_json, github: "Nebo15/logger_json", ref: "8e4290a"},
      {:myxql, ">= 0.0.0"},
      {:ranch, "~> 2.1", override: true},
      {:redix, ">= 0.0.0"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.5.3", only: :dev},
      {:phoenix_html_helpers, "~> 1.0.1"},
      {:phoenix_view, "~> 2.0.4"},
      {:phoenix, "~> 1.7.19"},
      {:plug_cowboy, "~> 2.7.2"},
      {:pot, "~> 1.0.2"},
      {:saxy, "~> 1.6"},
      {:spandex, "~> 3.2"},
      {:spandex_datadog, "~> 1.4"},
      {:spandex_ecto, "~> 0.7"},
      {:spandex_phoenix, "~> 1.1"},
      {:telemetry_metrics, "~> 1.1.0"},
      {:telemetry_poller, "~> 1.1.0"},
      {:ueberauth_github, "~> 0.8.3"},
      {:ueberauth_google, "~> 0.12.1"},
      {:mox, "~> 1.2", only: :test}
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

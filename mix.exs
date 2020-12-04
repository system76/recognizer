defmodule Recognizer.MixProject do
  use Mix.Project

  def project do
    [
      app: :recognizer,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
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
      {:argon2_elixir, "~> 2.1"},
      {:ecto_sql, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:myxql, "~> 0.2"},
      {:phoenix, "~> 1.4.11"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:ex_machina, "~> 2.3", only: :test},
      {:credo, "~> 1.1", only: :dev},
      {:sobelow, "~> 0.8", only: :dev}
    ]
  end

  defp releases do
    [
      recognizer: [
        include_executables_for: [:unix],
        applications: [recognizer: :permanent, runtime_tools: :permanent]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end

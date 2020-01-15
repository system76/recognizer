# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :recognizer,
  ecto_repos: [Recognizer.Repo]

config :recognizer, Recognizer.Repo,
  database: "recognizer",
  hostname: "localhost",
  password: "recognizer",
  port: 3306,
  username: "root"

# Configures the endpoint
config :recognizer, RecognizerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "C7MH9uVWoO/pu6bzVE96pGcQwR2PmgRe3EzYpjBa4tCnsjVt7EEEgzmrS3PdPZLn",
  render_errors: [view: RecognizerWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Recognizer.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :recognizer, Recognizer.Guardian,
  issuer: "recognizer",
  secret_key: "Secret key. You can use `mix guardian.gen.secret` to get one"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

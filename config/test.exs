import Config

config :bcrypt_elixir, :log_rounds, 1

config :recognizer, Recognizer.Repo,
  username: "root",
  password: "recognizer",
  database: "recognizer_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :recognizer, RecognizerWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

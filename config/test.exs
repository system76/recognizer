import Config

# Configure your database
config :recognizer, Recognizer.Repo,
  username: "root",
  password: "recognizer",
  database: "recognizer_test",
  hostname: Map.get(System.get_env(), "DB_HOST", "0.0.0.0"),
  pool: Ecto.Adapters.SQL.Sandbox,
  port: 3306

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :recognizer, RecognizerWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

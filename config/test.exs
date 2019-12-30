use Mix.Config

# Configure your database
config :recognizer, Recognizer.Repo,
  database: "system76",
  hostname: "localhost",
  password: "system76",
  pool: Ecto.Adapters.SQL.Sandbox,
  port: 3306,
  username: "root"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :recognizer, RecognizerWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

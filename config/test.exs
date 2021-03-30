import Config

config :recognizer,
  redis_host: System.get_env("REDIS_HOST", "localhost"),
  hal_url: "https://api-v2.genesis76.com"

config :argon2_elixir,
  t_cost: 1,
  m_cost: 8

config :recognizer, Recognizer.Repo,
  username: "root",
  password: "recognizer",
  database: "recognizer_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

config :recognizer, RecognizerWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

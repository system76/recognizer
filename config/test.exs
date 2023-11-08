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

config :hammer,
  backend:
    {Hammer.Backend.Redis,
     [
       expiry_ms: 60_000 * 60 * 2,
       redix_config: [host: System.get_env("REDIS_HOST", "localhost"), port: 6379],
       pool_size: 4,
       pool_max_overflow: 2
     ]}

config :recognizer, Recognizer.BigCommerce,
  client_id: "bc_id",
  client_secret: "bc_secret",
  access_token: "bc_access_token",
  store_hash: "bc_store_hash",
  login_uri: "http://localhost/"

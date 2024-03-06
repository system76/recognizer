import Config

config :recognizer,
  hal_url: "https://api-v2.genesis76.com",
  hal_token: "token"

config :recognizer, Recognizer.Repo,
  username: "root",
  password: "recognizer",
  database: "recognizer_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :recognizer, RecognizerWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch",
      "--no-stats-all",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :recognizer, RecognizerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/recognizer_web/(live|views)/.*(ex)$",
      ~r"lib/recognizer_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :hammer,
  backend:
    {Hammer.Backend.Redis,
     [
       expiry_ms: 60_000 * 60 * 2,
       redix_config: [host: "localhost", port: 6379],
       pool_size: 4,
       pool_max_overflow: 2
     ]}

config :recognizer, Recognizer.BigCommerce,
  client_id: "bc_id",
  client_secret: "bc_secret",
  access_token: "bc_access_token",
  store_hash: "bc_store_hash",
  login_uri: "http://localhost/login/",
  logout_uri: "http://localhost/logout",
  http_client: HTTPoison,
  enabled?: false

config :recognizer, Recognizer.Accounts,
  cache_expiry: 60 * 60 * 24 * 7

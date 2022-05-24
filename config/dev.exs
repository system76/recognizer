import Config

config :recognizer,
  hal_url: "https://api-v2.genesis76.com"

config :recognizer, Recognizer.Repo,
  username: "root",
  password: "recognizer",
  database: "recognizer_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :recognizer, RecognizerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "vbOPS+hzz+UAQRtWxIdqiKrcOuWpbLTfocvgvRVDR9P4JRfxtmWZa45H25iKKYoI",
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

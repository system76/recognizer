import Config

config :recognizer, RecognizerWeb.Endpoint,
  url: [scheme: "https", port: 443],
  http: [port: 8080],
  cache_static_manifest: "priv/static/cache_manifest.json",
  gzip: true,
  server: true

config :logger,
  backends: [LoggerJSON],
  level: :info

config :recognizer, Recognizer.Repo, log: false

config :recognizer, Recognizer.Notifications.Account, bullhorn_enabled: true

config :phoenix, :logger, false

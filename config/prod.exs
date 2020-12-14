import Config

config :recognizer, RecognizerWeb.Endpoint,
  url: [scheme: "https"],
  http: [port: 8080],
  cache_static_manifest: "priv/static/cache_manifest.json",
  gzip: true,
  server: true

config :logger,
  backends: [LoggerJSON],
  level: :info

config :recognizer, Recognizer.Repo, log: false

config :phoenix, :logger, false

config :appsignal, :config, active: true

config :ex_aws, enabled: true

config :recognizer, ExOauth2Provider,
  force_ssl_in_redirect_uri: true

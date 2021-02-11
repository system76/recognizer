import Config

config :recognizer, RecognizerWeb.Endpoint,
  url: [scheme: "https", port: 443],
  http: [port: 8080],
  cache_static_manifest: "priv/static/cache_manifest.json",
  gzip: true,
  server: true

config :recognizer,
  mailchimp: [
    base_url: "https://us10.api.mailchimp.com"
  ]

config :logger,
  backends: [LoggerJSON],
  level: :info

config :recognizer, Recognizer.Repo, log: false

config :phoenix, :logger, false

config :appsignal, :config, active: true

config :ex_aws, enabled: true

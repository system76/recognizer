import Config

config :recognizer, RecognizerWeb.Endpoint,
  url: [port: 443],
  http: [port: 8080],
  cache_static_manifest: "priv/static/cache_manifest.json",
  gzip: true,
  server: true

config :logger, level: :info

config :appsignal, :config,
  active: true,
  name: "Recognizer"

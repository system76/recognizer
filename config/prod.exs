import Config

config :recognizer, RecognizerWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info

config :appsignal, :config,
  active: true,
  name: "Recognizer"

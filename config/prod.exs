import Config

config :recognizer, RecognizerWeb.Endpoint,
  check_origin: false,
  http: [:inet6, port: 8080],
  server: true

config :logger, level: :debug

config :appsignal, :config,
  active: true,
  name: "Recognizer"

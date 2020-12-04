import Config

config :recognizer, RecognizerWeb.Endpoint,
  check_origin: false,
  force_ssl: [hstl: true],
  http: [:inet6, port: 8080]
  server: true

config :logger, level: :warn

config :appsignal, :config,
  active: true,
  name: "Recognizer"

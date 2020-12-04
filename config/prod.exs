import Config

config :recognizer, RecognizerWeb.Endpoint,
  force_ssl: [hstl: true],
  url: [host: "example.com", port: 80],
  http: [
    :inet6,
    port:
      System.get_env()
      |> Map.get("PORT", "4000")
      |> String.to_integer()
  ]

config :logger, level: :warn

config :appsignal, :config,
  active: true,
  name: "Recognizer"

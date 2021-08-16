defmodule RecognizerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :recognizer

  @session_options [
    store: :cookie,
    key: "_recognizer_key",
    signing_salt: "juvsYHmf"
  ]

  plug RecognizerWeb.HealthcheckPlug

  plug Plug.Static,
    at: "/",
    from: :recognizer,
    gzip: Application.get_env(:recognizer, __MODULE__)[:gzip],
    only: ~w(styles fonts images scripts favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :recognizer
  end

  plug CORSPlug
  plug Bottle.RequestIdPlug
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug LoggerJSON.Plug,
    metadata_formatter: LoggerJSON.Plug.MetadataFormatters.DatadogLogger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  plug RecognizerWeb.Router
end

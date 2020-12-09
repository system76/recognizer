import Config

config :recognizer,
  ecto_repos: [Recognizer.Repo]

config :recognizer, RecognizerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vbOPS+hzz+UAQRtWxIdqiKrcOuWpbLTfocvgvRVDR9P4JRfxtmWZa45H25iKKYoI",
  render_errors: [view: RecognizerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Recognizer.PubSub,
  live_view: [signing_salt: "YzwhzV25"],
  gzip: false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :appsignal, :config,
  name: "Recognizer",
  active: false,
  ignore_errors: [
    "Ecto.NoResultsError",
    "Phoenix.MissingParamError",
    "Phoenix.Router.NoRouteError",
    "Policy.Error"
  ]

import_config "#{Mix.env()}.exs"

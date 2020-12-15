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

config :logger_json, :backend, metadata: :all

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

config :recognizer, :message_queues, []

config :ex_aws,
  enabled: false,
  json_codec: Jason

config :recognizer, ExOauth2Provider,
  repo: Recognizer.Repo,
  resource_owner: Recognizer.Accounts.User,
  access_grant: Recognizer.OauthProvider.AccessGrant,
  access_token: Recognizer.OauthProvider.AccessToken,
  application: Recognizer.OauthProvider.Application,
  access_token_generator: {Recognizer.Guardian, :encode_and_sign_access_token},
  default_scopes: ~w(profile:read),
  optional_scopes: ~w(profile:read profile:write),
  authorization_code_expires_in: 600,
  access_token_expires_in: 7200,
  use_refresh_token: true,
  revoke_refresh_token_on_use: true,
  force_ssl_in_redirect_uri: false

config :recognizer, Recognizer.Guardian,
  issuer: "recognizer",
  secret_key: "g6Ddv3l/3cYkgtOwkhspAAcw0cjL3Pg23rnmt69UVYHi4WrU1smdFykZa0GfY4xl"

config :ueberauth, Ueberauth,
  base_path: "/oauth",
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user:email", send_redirect_uri: false]},
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: "",
  client_secret: ""

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "",
  client_secret: ""

import_config "#{Mix.env()}.exs"

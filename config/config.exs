import Config

config :recognizer,
  ecto_repos: [Recognizer.Repo],
  two_factor_issuer: "System76",
  redirect_url: false,
  redis_host: "localhost"

config :recognizer, RecognizerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vbOPS+hzz+UAQRtWxIdqiKrcOuWpbLTfocvgvRVDR9P4JRfxtmWZa45H25iKKYoI",
  render_errors: [
    view: RecognizerWeb.ErrorView,
    accepts: ~w(html json),
    layout: {RecognizerWeb.LayoutView, "error.html"}
  ],
  http: [
    protocol_options: [
      max_header_value_length: 8192
    ]
  ],
  pubsub_server: Recognizer.PubSub,
  live_view: [signing_salt: "YzwhzV25"],
  gzip: false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :trace_id, :span_id]

config :grpc, start_server: true

config :logger_json, :backend,
  formatter: LoggerJSON.Formatters.DatadogLogger,
  metadata: :all

config :phoenix, :json_library, Jason

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
  use_refresh_token: true,
  revoke_refresh_token_on_use: true,
  force_ssl_in_redirect_uri: false

config :recognizer, Recognizer.Guardian,
  issuer: "system76",
  secret_key: "g6Ddv3l/3cYkgtOwkhspAAcw0cjL3Pg23rnmt69UVYHi4WrU1smdFykZa0GfY4xl",
  token_ttl: %{
    "access" => {24, :hours},
    "reset_password" => {15, :minutes}
  }

config :guardian, Guardian.DB,
  repo: Recognizer.Repo,
  schema_name: "users_tokens",
  sweep_interval: 60

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

config :recognizer, Recognizer.Tracer,
  service: :recognizer,
  adapter: SpandexDatadog.Adapter,
  disabled?: true

config :spandex_ecto, SpandexEcto.EctoLogger,
  service: :system76,
  tracer: Recognizer.Tracer

config :spandex_phoenix, tracer: Recognizer.Tracer
config :spandex, :decorators, tracer: Recognizer.Tracer

config :recognizer, Recognizer.Accounts,
  cache_expiry: 60 * 15

import_config "#{Mix.env()}.exs"

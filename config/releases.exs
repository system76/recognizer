import Config

recognizer_config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :recognizer,
  redirect_url: recognizer_config["REDIRECT_URL"]

config :recognizer, RecognizerWeb.Endpoint,
  url: [host: System.get_env("DOMAIN")],
  secret_key_base: recognizer_config["SECRET_KEY_BASE"]

config :recognizer, Recognizer.Repo,
  username: recognizer_config["DB_USER"],
  password: recognizer_config["DB_PASS"],
  database: recognizer_config["DB_NAME"],
  hostname: recognizer_config["DB_HOST"],
  pool_size: recognizer_config["DB_POOL"]

config :recognizer,
  message_queues: [
    {Bottle.Account.V1.UserCreated,
     [recognizer_config["NOTIFICATION_SERVICE_SQS_URL"], recognizer_config["PAYMENT_SERVICE_SQS_URL"]]},
    {Bottle.Account.V1.TwoFactorRequested, recognizer_config["NOTIFICATION_SERVICE_SQS_URL"]},
    {Bottle.Account.V1.PasswordChanged, recognizer_config["NOTIFICATION_SERVICE_SQS_URL"]},
    {Bottle.Account.V1.PasswordReset, recognizer_config["NOTIFICATION_SERVICE_SQS_URL"]}
  ],
  two_factor_issuer: recognizer_config["TWO_FACTOR_ISSUER"]

config :ex_aws,
  access_key_id: recognizer_config["AWS_ACCESS_KEY_ID"],
  secret_access_key: recognizer_config["AWS_SECRET_ACCESS_KEY"],
  region: recognizer_config["AWS_REGION"]

config :appsignal, :config,
  push_api_key: recognizer_config["APPSIGNAL_KEY"],
  env: recognizer_config["ENVIRONMENT"]

config :recognizer, ExOauth2Provider,
  force_ssl_in_redirect_uri: Map.get(recognizer_config, "FORCE_SSL_OAUTH_APPLICATIONS", true)

config :recognizer, Recognizer.Guardian, secret_key: recognizer_config["GUARDIAN_KEY"]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: recognizer_config["GITHUB_CLIENT_ID"],
  client_secret: recognizer_config["GITHUB_CLIENT_SECRET"]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: recognizer_config["GOOGLE_CLIENT_ID"],
  client_secret: recognizer_config["GOOGLE_CLIENT_SECRET"]

config :recognizer, Recognizer.Tracer,
  disabled?: false,
  env: recognizer_config["ENVIRONMENT"]

import Config

recognizer_config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :recognizer, RecognizerWeb.Endpoint,
  url: [
    host: System.get_env("DOMAIN"),
    port: "PORT" |> System.get_env("80") |> String.to_integer()
  ],
  secret_key_base: recognizer_config["SECRET_KEY_BASE"]

config :recognizer, Recognizer.Repo,
  username: recognizer_config["DB_USER"],
  password: recognizer_config["DB_PASS"],
  database: recognizer_config["DB_NAME"],
  hostname: recognizer_config["DB_HOST"],
  pool_size: recognizer_config["DB_POOL"]

config :recognizer, Recognizer.Guardian, secret_key: recognizer_config["GUARDIAN_KEY"]

config :recognizer, :message_queues, [
  {Bottle.Notification.User.V1.Created, recognizer_config["NOTIFICATION_SERVICE_SQS_URL"]},
  {Bottle.Notification.User.V1.PasswordChanged, recognizer_config["NOTIFICATION_SERVICE_SQS_URL"]},
  {Bottle.Notification.User.V1.PasswordReset, recognizer_config["NOTIFICATION_SERVICE_SQS_URL"]}
]

config :ex_aws,
  access_key_id: recognizer_config["AWS_ACCESS_KEY_ID"],
  secret_access_key: recognizer_config["AWS_SECRET_ACCESS_KEY"],
  region: recognizer_config["AWS_REGION"]

config :appsignal, :config,
  push_api_key: recognizer_config["APPSIGNAL_KEY"],
  env: recognizer_config["APPSIGNAL_ENV"]

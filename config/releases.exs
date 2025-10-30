import Config

recognizer_config =
  "CONFIG"
  |> System.fetch_env!()
  |> Jason.decode!()

config :recognizer,
  redirect_url: recognizer_config["REDIRECT_URL"],
  hal_url: recognizer_config["HAL_URL"],
  hal_token: recognizer_config["HAL_TOKEN"]

config :recognizer, RecognizerWeb.Endpoint,
  url: [host: recognizer_config["DOMAIN"]],
  secret_key_base: recognizer_config["SECRET_KEY_BASE"]

config :recognizer, Recognizer.Repo,
  username: recognizer_config["DB_USER"],
  password: recognizer_config["DB_PASS"],
  database: recognizer_config["DB_NAME"],
  hostname: recognizer_config["DB_HOST"],
  pool_size: recognizer_config["DB_POOL"]

config :recognizer,
  two_factor_issuer: recognizer_config["TWO_FACTOR_ISSUER"],
  redis_host: recognizer_config["REDIS_HOST"]

config :amqp,
  connections: [
    rabbitmq_conn: [
      username: recognizer_config["RABBITMQ_USERNAME"],
      password: recognizer_config["RABBITMQ_PASSWORD"],
      host: recognizer_config["RABBITMQ_HOST"],
      port: recognizer_config["RABBITMQ_PORT"],
      ssl_options: [verify: :verify_none]
    ]
  ],
  channels: [
    events: [connection: :rabbitmq_conn]
  ]

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

config :hammer,
  backend:
    {Hammer.Backend.Redis,
     [
       expiry_ms: 60_000 * 60 * 2,
       redix_config: [
         host: recognizer_config["REDIS_HOST"],
         port: 6379
       ],
       pool_size: 4,
       pool_max_overflow: 2
     ]}

config :recognizer, Recognizer.BigCommerce,
  client_id: recognizer_config["BIGCOMMERCE_CLIENT_ID"],
  client_secret: recognizer_config["BIGCOMMERCE_CLIENT_SECRET"],
  access_token: recognizer_config["BIGCOMMERCE_ACCESS_TOKEN"],
  store_hash: recognizer_config["BIGCOMMERCE_STORE_HASH"],
  store_home_uri: recognizer_config["BIGCOMMERCE_HOME_URI"],
  login_path: recognizer_config["BIGCOMMERCE_LOGIN_PATH"],
  logout_path: recognizer_config["BIGCOMMERCE_LOGOUT_PATH"],
  http_client: HTTPoison,
  enabled?: true

config :recognizer, Recognizer.Accounts, cache_expiry: recognizer_config["ACCOUNT_CACHE_EXPIRY_SECONDS"]

config :recognizer, RecognizerWeb.Authentication, logout_redirect_uris: recognizer_config["LOGOUT_REDIRECT_URIS"]

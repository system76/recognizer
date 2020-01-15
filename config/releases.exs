import Config

config :recognizer, RecognizerWeb.Endpoint,
  url: [host: System.get_env("HOST"), port: 443],
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "80")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  force_ssl: [hstl: true]

config :recognizer, Recognizer.Repo,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  pool_size: String.to_integer(System.get_env("DB_POOL") || "10")

config :logger, level: :warn

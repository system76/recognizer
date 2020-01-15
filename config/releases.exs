import Config

config :recognizer, RecognizerWeb.Endpoint,
  url: [host: System.get_env("HOST"), port: 443],
  http: [
    :inet6,
    port:
      System.get_env()
      |> Map.get("PORT", "4000")
      |> String.to_integer()
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  force_ssl: [hstl: true]

config :recognizer, Recognizer.Repo,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  pool_size:
    System.get_env()
    |> Map.get("DB_POOL", "10")
    |> String.to_integer()

config :logger, level: :warn

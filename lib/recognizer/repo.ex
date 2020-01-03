defmodule Recognizer.Repo do
  use Ecto.Repo,
    otp_app: :recognizer,
    adapter: Ecto.Adapters.MyXQL

  def init(_, opts) do
    {:ok, build_opts(opts)}
  end

  defp build_opts(opts) do
    system_opts = [
      database: System.get_env("RECOGNIZER_DATABASE"),
      hostname: System.get_env("RECOGNIZER_HOSTNAME"),
      password: System.get_env("RECOGNIZER_PASSWORD"),
      username: System.get_env("RECOGNIZER_USERNAME"),
      pool_size: db_pool_size()
    ]

    without_nil = Enum.reject(system_opts, fn {_k, v} -> is_nil(v) end)

    Keyword.merge(opts, without_nil)
  end

  defp db_pool_size do
    System.get_env()
    |> Map.get("RECOGNIZER_DB_POOL", "10")
    |> String.to_integer()
  end
end

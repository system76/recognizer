defmodule Recognizer.Repo do
  use Ecto.Repo,
    otp_app: :recognizer,
    adapter: Ecto.Adapters.MyXQL

  def now() do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end

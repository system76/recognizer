defmodule Recognizer.Repo do
  use Ecto.Repo,
    otp_app: :recognizer,
    adapter: Ecto.Adapters.MyXQL
end

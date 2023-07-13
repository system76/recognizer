defmodule RecognizerWeb.Accounts.VerificationCodeController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  def new(conn, %{"code" => code}) do
    case Accounts.verify_user(code) do
      {:ok, user} ->
        Authentication.log_in_user(conn, user)

      {:error, error} ->
        conn
        |> put_status(400)
        |> render("error.html", error: error)
    end
  end
end

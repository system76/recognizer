defmodule RecognizerWeb.Accounts.VerificationCodeController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Notifications.Account, as: Notification
  alias RecognizerWeb.Authentication

  def new(conn, %{"code" => code}) do
    case Accounts.verify_user(code) do
      {:ok, user} ->
        Notification.deliver_user_created_message(user)
        Authentication.log_in_user(conn, user)

      {:error, error} ->
        conn
        |> put_status(400)
        |> render("error.html", error: error)
    end
  end
end

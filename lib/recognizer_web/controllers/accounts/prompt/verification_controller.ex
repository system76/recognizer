defmodule RecognizerWeb.Accounts.Prompt.VerificationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :ensure_user

  plug Hammer.Plug,
       [
         rate_limit: {"user:verification", @one_minute, 1},
         by: {:conn, &get_user_id_from_request/1}
       ]
       when action in [:resend]

  def new(%{assigns: %{user: %{verified_at: nil}}} = conn, _params) do
    render(conn, "new.html")
  end

  def new(%{assigns: %{user: user}} = conn, _params) do
    Authentication.log_in_user(conn, user)
  end

  def resend(%{assigns: %{user: user}} = conn, _params) do
    Accounts.resend_verification_code(user, &Routes.verification_code_url(conn, :new, &1))
    render(conn, "resent.html")
  end
end

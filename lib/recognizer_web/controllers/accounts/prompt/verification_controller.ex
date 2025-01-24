defmodule RecognizerWeb.Accounts.Prompt.VerificationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  @one_minute 60_000
  @one_hour 3_600_000

  plug :ensure_user

  plug Hammer.Plug,
       [
         rate_limit: {"user:verification", @one_minute, 2},
         by: {:conn, &get_user_id_from_unverified_request/1}
       ]
       when action in [:resend]
      #  when action in [:resend, :new]

  plug Hammer.Plug,
       [
         rate_limit: {"user:verification_hour", @one_hour, 6},
         by: {:conn, &get_user_id_from_unverified_request/1}
       ]
       when action in [:resend]
      #  when action in [:resend, :new]

  def new(%{assigns: %{user: %{verified_at: nil} = user}} = conn, _params) do
    render(conn, "new.html", resend?: false, email: user.email)
  end

  def new(%{assigns: %{user: user}} = conn, _params) do
    Authentication.log_in_user(conn, user)
  end

  def resend(%{assigns: %{user: %{verified_at: nil} = user}} = conn, _params) do
    Accounts.resend_verification_code(user, &Routes.verification_code_url(conn, :new, &1))
    render(conn, "new.html", resend?: true, email: user.email)
  end

  def resend(%{assigns: %{user: user}} = conn, _params) do
    Authentication.log_in_user(conn, user)
  end
end

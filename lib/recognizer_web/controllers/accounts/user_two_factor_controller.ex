defmodule RecognizerWeb.Accounts.UserTwoFactorController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Notifications.Account
  alias RecognizerWeb.Authentication

  def new(conn, _params) do
    current_user_id = get_session(conn, :current_user_id)
    current_user = Accounts.get_user!(current_user_id)

    %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(current_user)

    conn
    |> maybe_send_two_factor_notification(current_user, two_factor_method)
    |> render("new.html", two_factor_method: two_factor_method)
  end

  @doc """
  Handle a user creating a session with a two factor code
  """
  def create(conn, %{"user" => %{"two_factor_code" => two_factor_code}}) do
    current_user_id = get_session(conn, :current_user_id)
    current_user = Accounts.get_user!(current_user_id)

    if Authentication.valid_token?(two_factor_code, current_user) do
      Authentication.log_in_user(conn, current_user)
    else
      conn
      |> put_flash(:error, "Invalid security code")
      |> redirect(to: Routes.user_two_factor_path(conn, :new))
    end
  end

  @doc """
  Handle a user creating a session with a two factor recovery code
  """
  def create(conn, %{"user" => %{"recovery_code" => recovery_code}}) do
    current_user_id = get_session(conn, :current_user_id)
    current_user = Accounts.get_user!(current_user_id)

    case Accounts.recover_account(current_user, recovery_code) do
      {:ok, user} ->
        Authentication.log_in_user(conn, user)

      :error ->
        conn
        |> put_flash(:error, "Recovery code is invalid or has been used")
        |> redirect(to: Routes.user_two_factor_path(conn, :new))
    end
  end

  def resend(conn, _params) do
    current_user_id = get_session(conn, :current_user_id)
    current_user = Accounts.get_user!(current_user_id)

    conn
    |> send_two_factor_notification(current_user)
    |> put_flash(:info, "Two factor code has been resent")
    |> redirect(to: Routes.user_two_factor_path(conn, :new))
  end

  defp send_two_factor_notification(conn, %{notification_preference: %{two_factor: method}} = current_user) do
    send_two_factor_notification(conn, current_user, method)
  end

  defp send_two_factor_notification(conn, current_user, method) do
    token = Authentication.generate_token(current_user)
    Account.deliver_two_factor_token(current_user, token, method)
    put_session(conn, :two_factor_sent, true)
  end

  defp maybe_send_two_factor_notification(conn, current_user, method) do
    if get_session(conn, :two_factor_sent) == false and :app != method do
      send_two_factor_notification(conn, current_user, method)
    end

    conn
  end
end

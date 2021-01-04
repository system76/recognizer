defmodule RecognizerWeb.Accounts.UserTwoFactorController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.Accounts.User
  alias Recognizer.Notifications.Account
  alias RecognizerWeb.Authentication

  def new(conn, _params) do
    current_user = get_session(conn, :current_user)
    two_factor_method = current_user.notification_preference.two_factor

    conn
    |> maybe_send_two_factor_notification(current_user)
    |> render("new.html", two_factor_method: two_factor_method)
  end

  def create(conn, %{"user" => user_params}) do
    current_user = get_session(conn, :current_user)
    token = Map.get(user_params, "two_factor_code", "")

    if Authentication.valid_token?(token, current_user) do
      Authentication.log_in_user(conn, current_user)
    else
      conn
      |> put_flash(:error, "Invalid security code")
      |> redirect(to: Routes.user_two_factor_path(conn, :new))
    end
  end

  def resend(conn, _params) do
    current_user = get_session(conn, :current_user)

    conn
    |> send_two_factor_notification(current_user)
    |> put_flash(:info, "Two factor code has been resent")
    |> redirect(to: Routes.user_two_factor_path(conn, :new))
  end

  defp maybe_send_two_factor_notification(conn, current_user) do
    if get_session(conn, :two_factor_sent) != true do
      send_two_factor_notification(conn, current_user)
    else
      conn
    end
  end

  defp send_two_factor_notification(conn, %{notification_preference: %{two_factor: :app}}) do
    conn
  end

  defp send_two_factor_notification(conn, %User{} = user) do
    token = Authentication.generate_token(user)
    Account.deliver_two_factor_token(user, token)
    put_session(conn, :two_factor_sent, true)
  end
end

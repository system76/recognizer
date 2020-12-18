defmodule RecognizerWeb.Accounts.UserTwoFactorController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.Accounts.User
  alias Recognizer.Notifications.Account
  alias RecognizerWeb.Authentication

  def new(conn, _params) do
    current_user = get_session(conn, :current_user)

    render_two_factor(conn, current_user)
  end

  def create(conn, %{"user" => user_params}) do
    current_user = get_session(conn, :current_user)
    token = Map.get(user_params, "two_factor_code", "")

    if Authentication.valid_token?(token, current_user) do
      Authentication.log_in_user(conn, current_user)
    else
      conn
      |> put_flash(:error, "Invalid security code")
      |> render_two_factor(current_user)
    end
  end

  defp maybe_send_two_factor_notification(conn, _current_user, :app) do
    conn
  end

  defp maybe_send_two_factor_notification(conn, %User{} = user, _two_factor_method) do
    token = Authentication.generate_token(user)
    Account.deliver_two_factor_token(user, token)

    conn
  end

  defp render_two_factor(conn, current_user) do
    two_factor_method = current_user.notification_preference.two_factor

    conn
    |> maybe_send_two_factor_notification(current_user, two_factor_method)
    |> render("new.html", two_factor_method: two_factor_method)
  end
end

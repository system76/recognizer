defmodule RecognizerWeb.Accounts.UserTwoFactorController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Notifications.Account
  alias RecognizerWeb.Authentication

  @one_minute 60_000
  @one_hour 3_600_000

  plug :verify_user_id

  plug Hammer.Plug,
       [
         rate_limit: {"user:two_factor", @one_minute, 2},
         by: {:session, :two_factor_user_id}
       ]
       when action in [:resend]
      #  when action in [:resend, :create, :new]

  plug Hammer.Plug,
       [
         rate_limit: {"user:two_factor_hour", @one_hour, 6},
         by: {:session, :two_factor_user_id}
       ]
       when action in [:resend]
      #  when action in [:resend, :create, :new]

  @doc """
  Prompt the user for a two factor code on login
  """
  def new(conn, _params) do
    current_user_id = get_session(conn, :two_factor_user_id)
    current_user = Accounts.get_user!(current_user_id)

    %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(current_user)
    conn
    |> maybe_send_two_factor_notification(current_user, two_factor_method)
    |> render("new.html", two_factor_method: two_factor_method)
  end

  @doc """
  Verify a user creating a session with a two factor code
  """
  def create(conn, %{"user" => %{"two_factor_code" => two_factor_code}}) do
    current_user_id = get_session(conn, :two_factor_user_id)
    two_factor_issue_time = get_session(conn, :two_factor_issue_time)
    current_user = Accounts.get_user!(current_user_id)
    %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(current_user)

    if two_factor_issue_time == nil do
      current_time = System.system_time(:second)
      conn
        |> put_session(:two_factor_issue_time, current_time)
      if Authentication.valid_token?(two_factor_method, two_factor_code, current_time, current_user) do
        Authentication.log_in_user(conn, current_user)

      else
        conn
        |> put_flash(:error, "Invalid security code")
        |> redirect(to: Routes.user_two_factor_path(conn, :new))
      end

    else

      if Authentication.valid_token?(two_factor_method, two_factor_code, two_factor_issue_time, current_user) do
        Authentication.log_in_user(conn, current_user)
      else
        conn
        |> put_flash(:error, "Invalid security code")
        |> redirect(to: Routes.user_two_factor_path(conn, :new))
      end
    end
  end

  def resend(conn, _params) do
    current_user_id = get_session(conn, :two_factor_user_id)
    current_user = Accounts.get_user!(current_user_id)

    conn
    |> send_two_factor_notification(current_user)
    |> put_flash(:info, "Two factor code has been resent")
    |> redirect(to: Routes.user_two_factor_path(conn, :new))
  end

  defp send_two_factor_notification(conn, %{notification_preference: %{two_factor: method}} = current_user) do
    send_two_factor_notification(conn, current_user, method)
  end


  defp deliver_and_update_token(conn, current_user, method, issue_time) do
    token = Authentication.generate_token(method, issue_time, current_user)

    conn
    |> put_session(:two_factor_sent, true)
    |> put_session(:two_factor_issue_time, issue_time)
    |> tap(fn _conn -> Account.deliver_two_factor_token(current_user, token, method) end)
  end

  defp send_two_factor_notification(conn, current_user, method) do
    if method != :app do
      two_factor_issue_time = get_session(conn, :two_factor_issue_time)
      current_time = System.system_time(:second)

      cond do
        two_factor_issue_time == nil ->
          conn
          |> deliver_and_update_token(current_user, method, current_time)

        current_time - two_factor_issue_time > 60 ->
          conn
          |> deliver_and_update_token(current_user, method, current_time)

        true ->
          if get_session(conn, :two_factor_sent) == false do
            conn
            |> deliver_and_update_token(current_user, method, two_factor_issue_time)
          else
            conn
          end
      end
    else
      conn
    end
  end

  defp maybe_send_two_factor_notification(conn, current_user, method) do
    updated_conn = send_two_factor_notification(conn, current_user, method)
    updated_conn
  end

  defp verify_user_id(conn, _params) do
    if get_session(conn, :two_factor_user_id) == nil do
      RecognizerWeb.FallbackController.call(conn, {:error, :unauthenticated})
    else
      conn
    end
  end
end

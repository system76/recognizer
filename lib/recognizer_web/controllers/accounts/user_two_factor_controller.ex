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
    current_time = System.system_time(:second)
    %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(current_user)

    conn =
      if get_session(conn, :two_factor_issue_time) == nil do
        conn
        |> put_session(:two_factor_issue_time, current_time)
      else
        conn
      end

    two_factor_sent = get_session(conn, :two_factor_sent)

    conn =
      if two_factor_sent == false do
        conn
        |> maybe_send_two_factor_notification(current_user, two_factor_method)

        conn
        |> put_session(:two_factor_sent, true)
        |> put_session(:two_factor_issue_time, current_time)
      else
        conn
      end

    conn
    |> render("new.html", two_factor_method: two_factor_method)
  end

  @doc """
  Verify a user creating a session with a two factor code
  """
  def create(conn, %{"user" => %{"two_factor_code" => two_factor_code}}) do
    current_user_id = get_session(conn, :two_factor_user_id)
    current_user = Accounts.get_user!(current_user_id)
    current_time = System.system_time(:second)
    %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(current_user)

    two_factor_issue_time = get_session(conn, :two_factor_issue_time)

    # 15 minutes
    if current_time - two_factor_issue_time > 900 do
      conn = put_session(conn, :two_factor_issue_time, current_time)

      conn
      |> maybe_send_two_factor_notification(current_user, two_factor_method)

      conn
      |> put_flash(
        :error,
        "Two-factor code has expired. A new code has been sent. Please check your email for the newest two-factor code and try again."
      )
      |> redirect(to: Routes.user_two_factor_path(conn, :new))
    else
      if Authentication.valid_token?(two_factor_method, two_factor_code, two_factor_issue_time, current_user) do
        conn
        |> put_session(:two_factor_sent, false)
        |> put_session(:two_factor_issue_time, nil)
        |> Authentication.log_in_user(current_user)
      else
        conn
        |> put_flash(:error, "Invalid security code")
        |> redirect(to: Routes.user_two_factor_path(conn, :new))
      end
    end
  end

  @spec resend(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def resend(conn, _params) do
    current_time = System.system_time(:second)

    conn
    |> put_session(:two_factor_sent, false)
    |> put_session(:two_factor_issue_time, current_time)
    |> put_flash(:info, "Two factor code has been reset")
    |> redirect(to: Routes.user_two_factor_path(conn, :new))
  end

  defp deliver_and_update_token(conn, current_user, method, issue_time) do
    token = Authentication.generate_token(method, issue_time, current_user)

    conn
    |> tap(fn _conn -> Account.deliver_two_factor_token(current_user, token, method) end)
  end

  defp send_two_factor_notification(conn, current_user, method) do
    if method == :app || method == "app" do
      conn
    else
      two_factor_issue_time = get_session(conn, :two_factor_issue_time)
      current_time = System.system_time(:second)

      conn =
        if two_factor_issue_time == nil do
          conn
          |> deliver_and_update_token(current_user, method, current_time)
        else
          conn
          |> deliver_and_update_token(current_user, method, current_time)
        end

      conn
    end
  end

  defp maybe_send_two_factor_notification(conn, current_user, method) do
    conn
    |> send_two_factor_notification(current_user, method)
  end

  defp verify_user_id(conn, _params) do
    if get_session(conn, :two_factor_user_id) == nil do
      RecognizerWeb.FallbackController.call(conn, {:error, :unauthenticated})
    else
      conn
    end
  end
end

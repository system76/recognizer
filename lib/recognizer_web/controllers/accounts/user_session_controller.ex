defmodule RecognizerWeb.Accounts.UserSessionController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      {:ok, user} ->
        Authentication.log_in_user(conn, user, user_params)

      {:two_factor, user} ->
        conn
        |> put_session(:current_user_id, user.id)
        |> put_session(:two_factor_sent, false)
        |> redirect(to: Routes.user_two_factor_path(conn, :new))

      nil ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Authentication.conditional_flash(:info, "Logged out successfully.")
    |> Authentication.log_out_user()
  end
end

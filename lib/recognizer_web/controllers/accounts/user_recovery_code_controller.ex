defmodule RecognizerWeb.Accounts.UserRecoveryCodeController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  def new(conn, _params) do
    current_user_id = get_session(conn, :two_factor_user_id)

    if current_user_id != nil do
      render(conn, "new.html")
    else
      redirect(conn, to: Routes.user_session_path(conn, :create))
    end
  end

  @doc """
  Handle a user creating a session with a two factor recovery code
  """
  def create(conn, %{"user" => %{"recovery_code" => recovery_code}}) do
    current_user_id = get_session(conn, :two_factor_user_id)
    current_user = Accounts.get_user!(current_user_id)

    case Accounts.recover_account(current_user, recovery_code) do
      {:ok, user} ->
        Authentication.log_in_user(conn, user)

      :error ->
        conn
        |> put_flash(:error, "Recovery code is invalid or has been used")
        |> redirect(to: Routes.user_recovery_code_path(conn, :new))
    end
  end
end

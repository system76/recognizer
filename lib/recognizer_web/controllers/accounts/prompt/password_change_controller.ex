defmodule RecognizerWeb.Accounts.Prompt.PasswordChangeController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :ensure_user
  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"current_password" => password, "user" => user_params} = params) do
    user = conn.assigns.user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        Authentication.revoke_all_tokens(user)
        Authentication.log_in_user(conn, user, params)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  defp assign_changesets(conn, _opts) do
    assign(conn, :password_changeset, Accounts.change_user_password(conn.assigns.user))
  end
end

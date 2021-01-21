defmodule RecognizerWeb.Accounts.Prompt.PasswordChangeController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"current_password" => password, "user" => user_params} = params) do
    user_id = get_session(conn, :current_user_id)
    user = Accounts.get_user!(user_id)

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        IO.inspect(user, label: "updated user")
        Authentication.revoke_all_tokens(user)
        Authentication.log_in_user(conn, user, params)

      {:error, changeset} ->
        IO.inspect(changeset, label: "error")
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  defp assign_changesets(conn, _opts) do
    user_id = get_session(conn, :current_user_id)
    user = Accounts.get_user!(user_id)

    conn
    |> assign(:user, user)
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end

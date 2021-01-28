defmodule RecognizerWeb.Accounts.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    if Application.get_env(:recognizer, :redirect_url) do
      redirect(conn, external: Application.get_env(:recognizer, :redirect_url))
    else
      render(conn, "edit.html")
    end
  end

  def update(conn, %{"action" => "update", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user(user, user_params) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Settings has been updated.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        Authentication.revoke_all_tokens(user)

        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> Authentication.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_two_factor", "user" => %{"two_factor_enabled" => "0"}}) do
    user = Authentication.fetch_current_user(conn)

    with {:ok, _updated_user} <- Accounts.update_user_two_factor(user, %{"two_factor_enabled" => false}) do
      conn
      |> put_flash(:info, "Two factor has been disabled.")
      |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  def update(conn, %{"action" => "update_two_factor", "user" => %{"two_factor_enabled" => "1"}}) do
    user = Authentication.fetch_current_user(conn)

    conn
    |> put_session(:two_factor_user_id, user.id)
    |> redirect(to: Routes.live_path(conn, RecognizerWeb.Accounts.TwoFactorSettingsLive))
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = Authentication.fetch_current_user(conn)

    conn
    |> assign(:changeset, Accounts.change_user(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:two_factor_changeset, Accounts.change_user_two_factor(user))
  end
end

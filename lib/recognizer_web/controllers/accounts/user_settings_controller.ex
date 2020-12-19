defmodule RecognizerWeb.Accounts.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user_email(user, user_params) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Email has been updated.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> Authentication.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_authenticator(conn, params) do
    two_factor_code = Map.get(params, "two_factor_code", "")
    user = Authentication.fetch_current_user(conn)

    case Authentication.valid_token?(two_factor_code, user) do
      true ->
        {:ok, _} = Accounts.update_user_two_factor(user, %{"notification_preference" => %{"two_factor" => "app"}})

        conn
        |> put_flash(:info, "Authenticator app confirmed.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      false ->
        conn
        |> put_flash(:error, "Authenticator app security code is invalid.")
        |> render("confirm_authenticator.html",
          barcode: Authentication.generate_totp_barcode(user),
          totp_app_url: Authentication.get_totp_app_url(user)
        )
    end
  end

  def update(conn, %{
        "action" => "update_two_factor",
        "user" => %{"notification_preference" => %{"two_factor" => "app"}} = user_params
      }) do
    user = Authentication.fetch_current_user(conn)
    user_params = Map.drop(user_params, ["notification_preference"])

    case Accounts.update_user_two_factor(user, user_params) do
      {:ok, user} ->
        render(conn, "confirm_authenticator.html",
          barcode: Authentication.generate_totp_barcode(user),
          totp_app_url: Authentication.get_totp_app_url(user)
        )

      {:error, changeset} ->
        render(conn, "edit.html", two_factor_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_two_factor"} = params) do
    %{"user" => user_params} = params
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user_two_factor(user, user_params) do
      {:ok, %{notification_preference: %{two_factor: _}}} ->
        conn
        |> put_flash(:info, "Two-factor preferences have been updated.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", two_factor_changeset: changeset)
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = Authentication.fetch_current_user(conn)

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:two_factor_changeset, Accounts.change_user_two_factor(user))
  end
end

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

  def two_factor(conn, _params) do
    user = Authentication.fetch_current_user(conn)
    {:ok, %{two_factor_seed: seed}} = Accounts.get_new_two_factor_settings(user)

    render(conn, "confirm_two_factor.html",
      barcode: Authentication.generate_totp_barcode(user, seed),
      totp_app_url: Authentication.get_totp_app_url(user, seed)
    )
  end

  def two_factor_confirm(conn, params) do
    two_factor_code = Map.get(params, "two_factor_code", "")
    user = Authentication.fetch_current_user(conn)

    case Accounts.confirm_and_save_two_factor_settings(two_factor_code, user) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Two factor code verified.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      _ ->
        conn
        |> put_flash(:error, "Two factor code is invalid.")
        |> redirect(to: Routes.user_settings_path(conn, :confirm_two_factor))
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

  def update(conn, %{"action" => "update_two_factor", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)
    preference = get_in(user_params, ["notification_preference", "two_factor"])

    Accounts.generate_and_cache_new_two_factor_settings(user, preference)

    redirect(conn, to: Routes.user_settings_path(conn, :two_factor))
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = Authentication.fetch_current_user(conn)

    conn
    |> assign(:changeset, Accounts.change_user(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:two_factor_changeset, Accounts.change_user_two_factor(user))
  end
end

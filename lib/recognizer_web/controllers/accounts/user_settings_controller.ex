defmodule RecognizerWeb.Accounts.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    if Application.get_env(:recognizer, :redirect_url) && !get_session(conn, :bc) do
      redirect(conn, external: Application.get_env(:recognizer, :redirect_url))
    else
      render(conn, "edit.html")
    end
  end

  def two_factor(conn, _params) do
    user = Authentication.fetch_current_user(conn)

    # TODO params instead of cache
    case Accounts.get_new_two_factor_settings(user) do
      {:ok, %{two_factor_seed: seed, notification_preference: %{two_factor: "app"}}} ->
        IO.puts("rendering app 2fa confirmation...")

        render(conn, "confirm_two_factor.html",
          barcode: Authentication.generate_totp_barcode(user, seed),
          totp_app_url: Authentication.get_totp_app_url(user, seed)
        )

      {:ok, _} ->
        IO.puts("sending external 2fa notification...")

        # TODO not this path, a new page..
        redirect(conn, to: Routes.user_two_factor_path(conn, :new))
    end
  end

  def two_factor_confirm(conn, params) do
    two_factor_code = Map.get(params, "two_factor_code", "")
    user = Authentication.fetch_current_user(conn)

    case Accounts.confirm_and_save_two_factor_settings(two_factor_code, user) do
      {:ok, _updated_user} ->
        Accounts.clear_two_factor_settings(user)

        conn
        |> put_flash(:info, "Two factor code verified")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      _ ->
        conn
        |> put_flash(:error, "Two factor code is invalid")
        |> redirect(to: Routes.user_settings_path(conn, :two_factor_confirm))
    end
  end

  def update(conn, %{"action" => "update", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user(user, user_params) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Your settings have been updated.")
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

    redirect(conn, to: Routes.user_settings_path(conn, :review))
  end

  def review(conn, _params) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.get_new_two_factor_settings(user) do
      {:ok, %{recovery_codes: recovery_codes}} ->
        recovery_block =
          recovery_codes
          |> Enum.map(& &1.code)
          |> Enum.join("\n")

        conn
        |> render("recovery_codes.html", recovery_block: recovery_block)

      _ ->
        conn
        |> put_flash(:error, "Two factor setup expired or not yet initiated")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = Authentication.fetch_current_user(conn)

    conn
    |> assign(:changeset, Accounts.change_user(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:two_factor_changeset, Accounts.change_user_two_factor(user))
  end
end

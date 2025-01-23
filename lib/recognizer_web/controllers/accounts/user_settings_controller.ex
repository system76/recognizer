defmodule RecognizerWeb.Accounts.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Accounts.Role
  alias Recognizer.BigCommerce
  alias RecognizerWeb.Authentication

  @one_minute 60_000

  plug :assign_email_and_password_changesets
  plug :assign_common

  plug Hammer.Plug,
       [
         rate_limit: {"user_settings:two_factor", @one_minute, 2},
         by: {:conn, &__MODULE__.two_factor_rate_key/1},
         when_nil: :pass,
         on_deny: &__MODULE__.two_factor_rate_limited/2
       ]
       when action in [:two_factor_init]

  @doc """
  Prompt the user to edit account settings, main edit page
  """
  def edit(conn, _params) do
    if Application.get_env(:recognizer, :redirect_url) && !get_session(conn, :bc) do
      redirect(conn, external: Application.get_env(:recognizer, :redirect_url))
    else
      render(conn, "edit.html")
    end
  end

  @doc """
  Generate codes for a new two factor setup
  """
  def two_factor_init(conn, _params) do
    user = Authentication.fetch_current_user(conn)

    {:ok, %{two_factor_seed: seed, notification_preference: %{two_factor: method}} = settings} =
      Accounts.get_new_two_factor_settings(user)

    if method == "text" || method == "voice" || method == "email" do
      current_time = System.system_time(:second)
      session_time = get_session(conn, :two_factor_issue_time)

      issue_time = if session_time == nil do
        current_time - 61
      else
        session_time
      end

      updated_conn = case Accounts.send_new_two_factor_notification(user, settings, issue_time) do
        {:ok, update_issue_time} ->
          conn = put_session(conn, :two_factor_issue_time, update_issue_time)
          conn
      end
      render(updated_conn, "confirm_two_factor_external.html")
    else
      render(conn, "confirm_two_factor.html",
        barcode: Authentication.generate_totp_barcode(user, seed),
        totp_app_url: Authentication.get_totp_app_url(user, seed)
      )
    end
  end

  @doc """
  Rate limit 2fa setup only for text & voice, bypass for app.
  """
  def two_factor_rate_key(conn) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.get_new_two_factor_settings(user) do
      {:ok, %{notification_preference: %{two_factor: "app"}}} ->
        nil

      _ ->
        get_user_id_from_request(conn)
    end
  end

  @doc """
  Graceful error for 2fa retry rate limits
  """
  def two_factor_rate_limited(conn, _params) do
    conn
    |> put_flash(:error, "Too many requests, please wait and try again")
    |> render("confirm_two_factor_external.html")
    |> halt()
  end

  @doc """
  Confirming and saving a new two factor setup with user-provided code
  """
  def two_factor_confirm(conn, params) do
    two_factor_code = Map.get(params, "two_factor_code", "")
    user = Authentication.fetch_current_user(conn)
    current_time = System.system_time(:second)

    session_time = get_session(conn, :two_factor_issue_time)
    updated_conn = if session_time == nil do
      conn = put_session(conn, :two_factor_issue_time, current_time)
      conn
    else
      conn
    end

    counter = get_session(updated_conn, :two_factor_issue_time)
    case Accounts.confirm_and_save_two_factor_settings(two_factor_code, counter, user) do
      {:ok, _updated_user} ->
        Accounts.clear_two_factor_settings(user)

        updated_conn
        |> put_flash(:info, "Two factor code verified")
        |> redirect(to: Routes.user_settings_path(updated_conn, :edit))

      _ ->
        updated_conn
        |> put_flash(:error, "Two factor code is invalid")
        |> redirect(to: Routes.user_settings_path(updated_conn, :two_factor_confirm))
    end
  end

  @doc """
  Form submission for settings applied
  """
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

  # disable 2fa
  def update(conn, %{"action" => "update_two_factor", "user" => %{"two_factor_enabled" => "0"}}) do
    user = Authentication.fetch_current_user(conn)

    with {:ok, _updated_user} <- Accounts.update_user_two_factor(user, %{"two_factor_enabled" => false}) do
      conn
      |> put_flash(:info, "Two factor has been disabled.")
      |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  # enable 2fa
  def update(conn, %{
        "action" => "update_two_factor",
        "user" => %{"notification_preference" => %{"two_factor" => preference}}
      }) do
    %{phone_number: phone_number} = user = Authentication.fetch_current_user(conn)

    # phone number required for text/voice
    if (preference == "text" || preference == "voice") && phone_number == nil do
      conn
      |> put_flash(:error, "Phone number required for text and voice two-factor methods")
      |> redirect(to: Routes.user_settings_path(conn, :edit))
    else
      Accounts.generate_and_cache_new_two_factor_settings(user, preference)
      redirect(conn, to: Routes.user_settings_path(conn, :review))
    end
  end

  @doc """
  Review recovery codes for copying.
  """
  def review(conn, _params) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.get_new_two_factor_settings(user) do
      {:ok, %{recovery_codes: recovery_codes}} ->
        recovery_block =
          recovery_codes
          |> Enum.map_join("\n", & &1.code)

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

  defp assign_common(conn, _opts) do
    home_uri = BigCommerce.home_redirect_uri()

    # disable phone/text 2fa methods for admins
    is_admin =
      conn
      |> Authentication.fetch_current_user()
      |> Role.admin?()

    conn
    |> assign(:redirect_home, home_uri)
    |> assign(:allow_phone_methods, !is_admin)
  end
end

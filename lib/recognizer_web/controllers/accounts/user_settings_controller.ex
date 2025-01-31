defmodule RecognizerWeb.Accounts.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Notifications.Account
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

  def resend(conn, _params) do
    conn =
      conn
      |> put_session(:two_factor_sent, false)
      |> put_session(:two_factor_issue_time, System.system_time(:second))

    conn
    |> put_flash(:info, "Two factor code has been resent")
    |> redirect(to: Routes.user_settings_path(conn, :two_factor_init))
  end

  @doc """
  Generate codes for a new two factor setup
  """
  def two_factor_init(conn, _params) do
    user = Authentication.fetch_current_user(conn)
    current_user = Accounts.get_new_two_factor_settings(user)

    case current_user do
      {:error, _} ->
        conn
        |> put_flash(:error, "Two factor setup expired or not yet initiated")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:ok, nil} ->
        conn
        |> put_flash(:error, "Two factor setup expired or not yet initiated")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:ok, setting_user} ->
        %{two_factor_seed: seed, notification_preference: %{two_factor: method}} = setting_user

        method_atom = normalize_to_atom(method)

        if method in [:app, "app"] do
          render(conn, "confirm_two_factor.html",
            barcode: Authentication.generate_totp_barcode(user, seed),
            totp_app_url: Authentication.get_totp_app_url(user, seed)
          )
        else
          conn = two_factor_init_email(conn, setting_user, user, method_atom)

          IO.inspect(get_session(conn, :two_factor_sent, label: "two_factor_sent"))

          conn
          |> render("confirm_two_factor_external.html")
        end
    end
  end

  def two_factor_init_email(conn, setting_user, user, method_atom) do
    conn =
      if get_session(conn, :two_factor_issue_time) == nil do
        put_session(conn, :two_factor_issue_time, System.system_time(:second))
      else
        conn
      end

    two_factor_sent = get_session(conn, :two_factor_sent)

    conn =
      if two_factor_sent do
        conn
      else
        conn
        |> send_two_factor_notification(setting_user, user, method_atom)
        |> put_session(:two_factor_sent, true)
      end
  end

  @doc """
  Confirming and saving a new two factor setup with user-provided code
  """
  def two_factor_confirm(conn, params) do
    user = Authentication.fetch_current_user(conn)
    current_user = Accounts.get_new_two_factor_settings(user)

    two_factor_code = Map.get(params, "two_factor_code")
    {:ok, %{notification_preference: %{two_factor: method}} = setting_user} = current_user

    current_time = System.system_time(:second)
    conn = ensure_two_factor_issue_time(conn, current_time)

    two_factor_issue_time = get_session(conn, :two_factor_issue_time)
    method_atom = normalize_to_atom(method)

    if Authentication.valid_token?(method_atom, two_factor_code, two_factor_issue_time, setting_user.two_factor_seed) do
      if current_time - two_factor_issue_time > 900 do
        conn =
          conn
          |> put_session(:two_factor_issue_time, current_time)

        conn
        |> send_two_factor_notification(setting_user, user, method_atom)
        |> put_flash(
          :error,
          "Two-factor code has expired. A new code has been sent. Please check your email for the newest two-factor code and try again."
        )
        |> redirect(to: Routes.user_settings_path(conn, :two_factor_confirm))
      else
        handle_two_factor_settings(conn, user, two_factor_code, method_atom)
      end
    else
      conn
      |> put_flash(:error, "Two factor code is invalid")
      |> redirect(to: Routes.user_settings_path(conn, :two_factor_confirm))
    end
  end

  defp ensure_two_factor_issue_time(conn, current_time) do
    if get_session(conn, :two_factor_issue_time) == nil do
      put_session(conn, :two_factor_issue_time, current_time)
    else
      conn
    end
  end

  defp handle_two_factor_settings(conn, user, two_factor_code, method) do
    two_factor_issue_time = get_session(conn, :two_factor_issue_time)

    case Accounts.confirm_and_save_two_factor_settings(two_factor_code, two_factor_issue_time, user, method) do
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

  def normalize_to_atom(input) do
    cond do
      is_atom(input) -> input
      is_binary(input) -> String.to_existing_atom(input)
      true -> raise ArgumentError, "Input must be a string or an atom"
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
        conn = put_session(conn, :two_factor_sent, false)

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

  defp send_two_factor_notification(conn, current_user, user, method) do
    if method in ["app", :app] do
      conn
    else
      two_factor_issue_time = get_session(conn, :two_factor_issue_time)
      current_time = System.system_time(:second)

      if two_factor_issue_time == nil do
        conn
        |> deliver_and_update_token(current_user, user, method, current_time)
      else
        conn
        |> deliver_and_update_token(current_user, user, method, two_factor_issue_time)
      end
    end
  end

  defp deliver_and_update_token(conn, user, current_user, method, issue_time) do
    # %{two_factor_seed: two_factor_seed} = current_user

    if method in ["app", :app] do
      conn
    else
      token = Authentication.generate_token(method, issue_time, user.two_factor_seed)

      conn
      |> tap(fn _conn -> Account.deliver_two_factor_token(current_user, token, method) end)
    end
  end
end

defmodule RecognizerWeb.Accounts.UserSettingsControllerTest do
  use RecognizerWeb.ConnCase

  import Mox
  import Recognizer.AccountFactory
  import Recognizer.BigCommerceTestHelpers

  alias Recognizer.Accounts
  alias Recognizer.Accounts.User
  alias Recognizer.Repo
  alias RecognizerWeb.Authentication

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Update Profile</h2>"
      assert response =~ "Authenticator App"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end

    test "hides text/voice options for admin", %{conn: conn} do
      %{conn: conn} = register_and_log_in_admin(%{conn: conn})
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Authenticator App"
      refute response =~ "Text Message"
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => user.password,
          "user" => %{
            "password" => "NeWVa3!pa33wor@d",
            "password_confirmation" => "NeWVa3!pa33wor@d"
          }
        })

      assert redirected_to(new_password_conn) == Routes.user_settings_path(conn, :edit)
      assert Flash.get(new_password_conn.assigns.flash, :info) =~ "Password updated successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "NeWVa3!pa33wor@d")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Update Password</h2>"
      assert response =~ "must contain a number"
      assert response =~ "does not match password"
      assert response =~ "is not valid"
    end
  end

  describe "PUT /users/settings (change profile form)" do
    setup :verify_on_exit!

    test "updates the user email", %{conn: conn, user: user} do
      expect(HTTPoisonMock, :put, 1, fn _, _, _ -> ok_bigcommerce_response() end)

      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update",
          "user" => %{"email" => build(:email)}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert Flash.get(conn.assigns.flash, :info) =~ "Your settings have been updated"
      refute Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Update Profile</h2>"
      assert response =~ "must have the @ sign, no spaces and a top level domain"
    end

    test "does not update first name on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update",
          "user" => %{"first_name" => "https://example.org"}
        })

      response = html_response(conn, 200)
      assert response =~ "Update Profile</h2>"
      assert response =~ "must not contain special characters"
    end

    test "does not update last name on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update",
          "user" => %{"last_name" => "https://example.org"}
        })

      response = html_response(conn, 200)
      assert response =~ "Update Profile</h2>"
      assert response =~ "must not contain special characters"
    end

    test "update two-factor allows app setup without a phone number", %{conn: conn, user: user} do
      stub(HTTPoisonMock, :put, fn _, _, _ -> ok_bigcommerce_response() end)
      Accounts.update_user(user, %{phone_number: nil})

      conn =
        put(conn, Routes.user_settings_path(conn, :edit), %{
          "action" => "update_two_factor",
          "user" => %{"notification_preference" => %{"two_factor" => :app}}
        })

      assert redirected_to(conn) =~ "/settings/two-factor/review"
      refute Flash.get(conn.assigns.flash, :error)
    end
  end

  describe "GET /users/settings/two-factor/review (backup codes)" do
    test "gets review page after 2fa setup", %{conn: conn, user: user} do
      Accounts.generate_and_cache_new_two_factor_settings(user, :app)
      conn = get(conn, Routes.user_settings_path(conn, :review))
      assert html_response(conn, 200) =~ "copy your recovery codes"
    end

    test "review 2fa without cached codes is redirected with flash error", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :review))
      _response = html_response(conn, 302)
      assert Flash.get(conn.assigns.flash, :error) == "Two factor setup expired or not yet initiated"
    end
  end

  describe "GET /users/settings/two-factor (init)" do
    test "/two-factor page is rendered for with settings for app, doesn't rate limit", %{conn: conn, user: user} do
      Accounts.generate_and_cache_new_two_factor_settings(user, :app)
      conn = get(conn, Routes.user_settings_path(conn, :two_factor_init))
      assert html_response(conn, 200) =~ "Configure App"
      result2 = get(conn, Routes.user_settings_path(conn, :two_factor_init))
      assert html_response(result2, 200) =~ "Configure App"
      result3 = get(conn, Routes.user_settings_path(conn, :two_factor_init))
      assert html_response(result3, 200) =~ "Configure App"
      refute Flash.get(result3.assigns.flash, :error)
    end

    test "/two-factor loads for email, limits retries", %{conn: conn, user: user} do
      Accounts.generate_and_cache_new_two_factor_settings(user, :email)
      result1 = get(conn, Routes.user_settings_path(conn, :two_factor_init))
      assert html_response(result1, 200) =~ "Enter the provided 6-digit code"
      result2 = get(conn, Routes.user_settings_path(conn, :two_factor_init))
      assert html_response(result2, 200) =~ "Enter the provided 6-digit code"
      result3 = get(conn, Routes.user_settings_path(conn, :two_factor_init))
      assert html_response(result3, 200) =~ "Enter the provided 6-digit code"
      assert Flash.get(result3.assigns.flash, :error) =~ "Too many requests"
    end
  end

  describe "POST /users/settings/two-factor (confirm)" do
    test "confirm saves and clears cache", %{conn: conn, user: user} do
      settings = Accounts.generate_and_cache_new_two_factor_settings(user, :app)

      token = Authentication.generate_token(:app, 0, settings)
      params = %{"two_factor_code" => token}

      conn = post(conn, Routes.user_settings_path(conn, :two_factor_confirm), params)

      assert redirected_to(conn) =~ "/settings"
      assert Flash.get(conn.assigns.flash, :info) =~ "Two factor code verified"

      %{recovery_codes: recovery_codes} =
        User
        |> Repo.get(user.id)
        |> Repo.preload(:recovery_codes)

      refute Enum.empty?(recovery_codes)

      assert {:ok, nil} = Accounts.get_new_two_factor_settings(user)
    end

    test "confirm redirects without cached settings", %{conn: conn, user: user} do
      settings = Accounts.generate_and_cache_new_two_factor_settings(user, :app)
      token = Authentication.generate_token(:app, 0, settings)
      Accounts.clear_two_factor_settings(user)
      params = %{"two_factor_code" => token}
      conn = post(conn, Routes.user_settings_path(conn, :two_factor_confirm), params)
      assert redirected_to(conn) =~ "/two-factor"
      assert Flash.get(conn.assigns.flash, :error) =~ "Two factor code is invalid"
    end
  end
end

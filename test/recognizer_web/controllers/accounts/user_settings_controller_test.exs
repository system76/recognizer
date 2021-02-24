defmodule RecognizerWeb.Accounts.UserSettingsControllerTest do
  use RecognizerWeb.ConnCase

  import Mox
  import Recognizer.AccountFactory

  alias Recognizer.Accounts

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Log Out</h2>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
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
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
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
      assert response =~ "Change Password</h2>"
      assert response =~ "must contain a number"
      assert response =~ "does not match password"
      assert response =~ "is not valid"
    end
  end

  describe "PUT /users/settings (change profile form)" do
    setup :verify_on_exit!

    test "updates the user email", %{conn: conn, user: user} do
      expect(Recognizer.MockMailchimp, :update_user, fn user ->
        {:ok, user}
      end)

      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update",
          "user" => %{"email" => build(:email)}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Settings has been updated"
      refute Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Profile</h2>"
      assert response =~ "must have the @ sign and no spaces"
    end
  end
end

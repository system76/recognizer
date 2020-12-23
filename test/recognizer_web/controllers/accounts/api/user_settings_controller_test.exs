defmodule RecognizerWeb.Api.UserSettingsControllerTest do
  use RecognizerWeb.ConnCase

  describe "GET /api/settings" do
    setup [:register_and_log_in_user]

    test "GET /api/settings", %{conn: conn, user: %{id: user_id}} do
      conn = get(conn, "/api/settings")
      assert %{"user" => %{"id" => ^user_id}} = json_response(conn, 200)
    end
  end

  describe "PUT /api/settings" do
    setup [:register_and_log_in_user]

    test "PUT /api/settings with `update` action", %{conn: conn, user: %{id: user_id}} do
      conn = put(conn, "/api/settings", %{"action" => "update", "user" => %{"first_name" => "Updated"}})
      assert %{"user" => %{"id" => ^user_id, "first_name" => "Updated"}} = json_response(conn, 200)
    end

    test "PUT /api/settings with `update_password` action", %{conn: conn, user: user} do
      conn =
        put(conn, "/api/settings", %{
          "action" => "update_password",
          "current_password" => Recognizer.AccountsFixtures.valid_user_password(),
          "user" => %{
            "password" => "Rec0gnizer!",
            "password_confirmation" => "Rec0gnizer!"
          }
        })

      %{id: user_id, hashed_password: existing_password_hash} = user
      assert %{"user" => %{"id" => ^user_id}} = json_response(conn, 200)
      refute %{hashed_password: existing_password_hash} == Recognizer.Repo.get(Recognizer.Accounts.User, user.id)
    end

    test "PUT /api/settings with `update_two_factor` action", %{conn: conn} do
      conn =
        put(conn, "/api/settings", %{
          "action" => "update_two_factor",
          "user" => %{"notification_preference" => %{"two_factor" => "app"}}
        })

      assert %{"two_factor" => %{"barcode" => _, "totp_app_url" => _}} = json_response(conn, 202)
    end
  end
end

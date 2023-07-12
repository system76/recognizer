defmodule RecognizerWeb.Api.UserSettingsControllerTest do
  use RecognizerWeb.ConnCase

  import Mox
  import Recognizer.AccountFactory

  describe "GET /api/settings" do
    test "two factor is reflected", %{conn: conn} do
      %{id: user_id} = user = :user |> build() |> add_two_factor(:app) |> insert()
      conn = conn |> log_in_user(user) |> get("/api/settings")

      assert %{
               "user" => %{
                 "id" => ^user_id,
                 "two_factor_enabled" => true
               }
             } = json_response(conn, 200)
    end

    test "shows third_party_login as true when logged in through oauth", context do
      %{conn: conn, user: %{id: user_id}} = register_and_log_in_oauth_user(context)
      conn = get(conn, "/api/settings")

      assert %{
               "user" => %{
                 "id" => ^user_id,
                 "third_party_login" => true
               }
             } = json_response(conn, 200)
    end
  end

  setup :register_and_log_in_user

  describe "PUT /api/settings" do
    setup :verify_on_exit!

    test "PUT /api/settings with `update` action", %{conn: conn, user: %{id: user_id}} do
      conn = put(conn, "/api/settings", %{"action" => "update", "user" => %{"first_name" => "Updated"}})
      assert %{"user" => %{"id" => ^user_id, "first_name" => "Updated"}} = json_response(conn, 200)
    end

    test "don't allow special characters in the first name", %{conn: conn, user: %{id: user_id}} do
      conn = put(conn, "/api/settings", %{"action" => "update", "user" => %{"first_name" => "http://example.com"}})
      assert %{"errors" => %{"first_name" => ["must not contain special characters"]}} = json_response(conn, 400)
    end

    test "don't allow special characters in the last name", %{conn: conn, user: %{id: user_id}} do
      conn = put(conn, "/api/settings", %{"action" => "update", "user" => %{"last_name" => "http://example.com"}})
      assert %{"errors" => %{"last_name" => ["must not contain special characters"]}} = json_response(conn, 400)
    end

    test "PUT /api/settings with `update_password` action", %{conn: conn, user: user} do
      conn =
        put(conn, "/api/settings", %{
          "action" => "update_password",
          "current_password" => user.password,
          "user" => %{
            "password" => "Rec0gnizer!",
            "password_confirmation" => "Rec0gnizer!"
          }
        })

      %{id: user_id, hashed_password: existing_password_hash} = user
      assert %{"user" => %{"id" => ^user_id}} = json_response(conn, 200)
      refute %{hashed_password: existing_password_hash} == Recognizer.Repo.get(Recognizer.Accounts.User, user.id)
    end
  end
end

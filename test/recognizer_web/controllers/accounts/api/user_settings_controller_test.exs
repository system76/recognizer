defmodule RecognizerWeb.Api.UserSettingsControllerTest do
  use RecognizerWeb.ConnCase

  import Mox
  import Recognizer.AccountsFixtures

  setup %{conn: conn} do
    user = :user |> build() |> add_two_factor(:app) |> insert()

    %{
      conn: log_in_user(conn, user),
      user: user
    }
  end

  describe "GET /api/settings" do
    test "GET /api/settings", %{conn: conn, user: %{id: user_id}} do
      conn = get(conn, "/api/settings")
      assert %{"user" => %{"id" => ^user_id, "two_factor_enabled" => true}} = json_response(conn, 200)
    end
  end

  describe "PUT /api/settings" do
    setup :verify_on_exit!

    test "PUT /api/settings with `update` action", %{conn: conn, user: %{id: user_id}} do
      expect(Recognizer.MockMailchimp, :update_user, fn user ->
        {:ok, user}
      end)

      conn = put(conn, "/api/settings", %{"action" => "update", "user" => %{"first_name" => "Updated"}})
      assert %{"user" => %{"id" => ^user_id, "first_name" => "Updated"}} = json_response(conn, 200)
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

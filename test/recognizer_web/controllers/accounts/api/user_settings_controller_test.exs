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

    test "returns recovery codes and barcode with `update_two_factor` action", %{conn: conn} do
      conn =
        put(conn, "/api/settings", %{
          "action" => "update_two_factor",
          "user" => %{"notification_preference" => %{"two_factor" => "app"}}
        })

      assert %{"two_factor" => %{"barcode" => _, "totp_app_url" => _, "recovery_codes" => _}} = json_response(conn, 202)
    end

    test "returns recovery codes with `update_two_factor` action", %{conn: conn} do
      conn =
        put(conn, "/api/settings", %{
          "action" => "update_two_factor",
          "user" => %{"notification_preference" => %{"two_factor" => "text"}}
        })

      assert %{"two_factor" => %{"method" => "text", "recovery_codes" => _}} = json_response(conn, 202)
    end

    test "returns the user with `update_two_factor` action and `two_factor_enabled` is false", %{conn: conn} do
      conn =
        put(conn, "/api/settings", %{
          "action" => "update_two_factor",
          "user" => %{"two_factor_enabled" => false}
        })

      assert %{"user" => %{"two_factor_enabled" => false}} = json_response(conn, 200)
    end
  end

  describe "POST /api/confirm_two_factor" do
    test "confirms the two factor code and updates the user's settings", %{conn: conn, user: user} do
      %{recovery_codes: recovery_codes, two_factor_seed: seed} =
        Recognizer.Accounts.generate_and_cache_new_two_factor_settings(user, "text")

      valid_code = RecognizerWeb.Authentication.generate_token(seed)

      conn =
        post(conn, "/api/confirm_two_factor", %{
          "user" => %{"two_factor_code" => valid_code}
        })

      assert json_response(conn, 200)

      assert %{recovery_codes: codes, two_factor_seed: ^seed} =
               Recognizer.Accounts.User
               |> Recognizer.Repo.get(user.id)
               |> Recognizer.Repo.preload(:recovery_codes)

      assert Enum.map(recovery_codes, &Map.get(&1, :code)) == Enum.map(codes, &Map.get(&1, :code))
    end
  end
end

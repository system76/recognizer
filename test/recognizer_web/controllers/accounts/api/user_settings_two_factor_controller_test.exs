defmodule RecognizerWeb.Api.UserSettingsTwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  setup %{conn: conn} do
    user = :user |> insert()

    %{
      conn: log_in_user(conn, user),
      user: user
    }
  end

  defp new_user_conn() do
    conn = Phoenix.ConnTest.build_conn()
    user = :user |> insert()

    Recognizer.Accounts.generate_and_cache_new_two_factor_settings(user, "email")
    log_in_user(conn, user)
  end

  describe "two factor not setup" do
    test "GET /api/settings/two-factor sends empty view when no 2fa setup", %{conn: conn} do
      conn = get(conn, "/api/settings/two-factor")
      assert %{"two_factor" => nil} = json_response(conn, 200)
    end
  end

  describe "two factor setup" do
    setup %{user: user} do
      Recognizer.Accounts.generate_and_cache_new_two_factor_settings(user, "app")
    end

    test "GET /api/settings/two-factor", %{conn: conn} do
      conn = get(conn, "/api/settings/two-factor")
      assert %{"two_factor" => %{"method" => "app"}} = json_response(conn, 200)
    end

    test "returns recovery codes and barcode enable action", %{conn: conn} do
      conn = put(conn, "/api/settings/two-factor", %{"enabled" => true, "type" => "app"})
      assert %{"two_factor" => %{"barcode" => _, "totp_app_url" => _, "recovery_codes" => _}} = json_response(conn, 202)
    end

    test "returns success when sending two factor test notification", %{conn: conn} do
      conn = post(conn, "/api/settings/two-factor/send")
      assert json_response(conn, 202)
    end

    test "rate limits two factor notification", %{conn: conn} do
      Enum.each(0..20, fn _ -> post(conn, "/api/settings/two-factor/send") end)

      conn = post(conn, "/api/settings/two-factor/send")
      assert response(conn, 429)
    end

    test "rate limits by user id", %{conn: conn} do
      Enum.each(0..20, fn _ ->
        post(new_user_conn(), "/api/settings/two-factor/send")
      end)

      conn = post(conn, "/api/settings/two-factor/send")
      assert json_response(conn, 202)
    end

    test "confirms the two factor code and updates the user's settings", %{conn: conn, user: user} do
      %{recovery_codes: recovery_codes, two_factor_seed: seed} =
        Recognizer.Accounts.generate_and_cache_new_two_factor_settings(user, :email)

      counter = System.system_time(:second)
      conn = put_session(conn, :two_factor_issue_time, counter)

      valid_code = RecognizerWeb.Authentication.generate_token("email", counter, seed)
      conn = put(conn, "/api/settings/two-factor", %{"verification" => valid_code})

      assert json_response(conn, 200)

      assert %{recovery_codes: codes, two_factor_seed: ^seed} =
               Recognizer.Accounts.User
               |> Recognizer.Repo.get(user.id)
               |> Recognizer.Repo.preload(:recovery_codes)

      assert Enum.map(recovery_codes, &Map.get(&1, :code)) == Enum.map(codes, &Map.get(&1, :code))
    end
  end

  describe "two factor enabled" do
    setup %{conn: conn} do
      user = :user |> build() |> add_two_factor(:app) |> insert()

      %{
        conn: log_in_user(conn, user),
        user: user
      }
    end

    test "disables two factor when enabled is set to false", %{conn: conn} do
      conn = put(conn, "/api/settings/two-factor", %{"enabled" => false})
      assert %{"two_factor" => nil, "user" => %{"two_factor_enabled" => false}} = json_response(conn, 200)
    end
  end
end

defmodule RecognizerWeb.Accounts.UserRecoveryCodeControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture() |> add_two_factor()

    %{
      conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          current_user_id: user.id
        }),
      user: user
    }
  end

  describe "GET /recovery-code" do
    test "renders the two factor input page", %{conn: conn} do
      conn = get(conn, Routes.user_recovery_code_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Recovery Code</h2>"
    end
  end

  describe "POST /recovery-code" do
    test "redirects to user settings for successful recovery code", %{conn: conn, user: user} do
      %{recovery_codes: [%{code: recovery_code} | tail]} = user

      conn = post(conn, Routes.user_recovery_code_path(conn, :create), %{"user" => %{"recovery_code" => recovery_code}})
      assert redirected_to(conn) == "/settings"

      %{recovery_codes: remaining_codes} = Recognizer.Repo.preload(user, :recovery_codes, force: true)
      assert length(remaining_codes) == length(tail)
    end

    test "allow using a recovery code out of order", %{conn: conn, user: user} do
      recovery_code = Enum.at(user.recovery_codes, 4).code

      conn = post(conn, Routes.user_recovery_code_path(conn, :create), %{"user" => %{"recovery_code" => recovery_code}})
      assert redirected_to(conn) == "/settings"
    end

    test "emits error message with invalid recovery code", %{conn: conn} do
      conn =
        post(conn, Routes.user_recovery_code_path(conn, :create), %{
          "user" => %{"recovery_code" => "INVALID"}
        })

      assert redirected_to(conn) == "/recovery-code"
      assert get_flash(conn, :error) =~ "invalid"
    end
  end
end

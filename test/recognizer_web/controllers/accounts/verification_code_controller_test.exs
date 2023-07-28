defmodule RecognizerWeb.Accounts.UserVerificationCodeControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  setup do
    %{user: insert(:user, verified_at: nil)}
  end

  describe "GET /verify" do
    test "shows message for an expired code", %{conn: conn} do
      conn = get(conn, Routes.verification_code_path(conn, :new, "expired"))
      response = html_response(conn, 200)
      assert response =~ "Expired Verification Code</h2>"
    end

    test "verifies a valid code", %{conn: conn, user: user} do
      verification = insert(:verification_code, user: user)
      conn = get(conn, Routes.verification_code_path(conn, :new, verification.code))
      assert redirected_to(conn) =~ "/settings"
    end

    test "verifies a valid code multiple times", %{conn: conn, user: user} do
      verification = insert(:verification_code, user: user)
      conn = get(conn, Routes.verification_code_path(conn, :new, verification.code))
      conn = get(conn, Routes.verification_code_path(conn, :new, verification.code))
      conn = get(conn, Routes.verification_code_path(conn, :new, verification.code))
      assert redirected_to(conn) =~ "/settings"
    end
  end
end

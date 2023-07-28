defmodule RecognizerWeb.Accounts.Prompt.VerificationCodeControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  setup %{conn: conn} do
    user = insert(:user, verified_at: nil)
    verified_user = insert(:user)

    %{
      unverified_conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          prompt_user_id: user.id
        }),
      verified_conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          prompt_user_id: verified_user.id
        }),
      empty_conn: conn
    }
  end

  describe "GET /prompt/verification" do
    test "renders the verification required page for an unverified user", %{unverified_conn: conn} do
      conn = get(conn, Routes.prompt_verification_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Account Verification Pending</h2>"
    end

    test "redirects verified user", %{verified_conn: conn} do
      conn = get(conn, Routes.prompt_verification_path(conn, :new))
      assert redirected_to(conn) =~ "/settings"
    end

    test "redirects anonymous user", %{empty_conn: conn} do
      conn = get(conn, Routes.prompt_verification_path(conn, :new))
      assert redirected_to(conn) =~ "/login"
    end
  end

  describe "POST /prompt/verification" do
    test "resends the verification required page for an unverified user", %{unverified_conn: conn} do
      conn = post(conn, Routes.prompt_verification_path(conn, :resend))
      response = html_response(conn, 200)
      assert response =~ "Account Verification Pending</h2>"
      assert response =~ "<p>We've sent you another copy of the verification email.</p>"
    end

    test "redirects verified user", %{verified_conn: conn} do
      conn = post(conn, Routes.prompt_verification_path(conn, :resend))
      assert redirected_to(conn) =~ "/settings"
    end

    test "ignores anonymous user", %{empty_conn: conn} do
      conn = post(conn, Routes.prompt_verification_path(conn, :resend))
      assert redirected_to(conn) =~ "/login"
    end
  end
end

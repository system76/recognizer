defmodule RecognizerWeb.Accounts.UserTwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountsFixtures

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  setup %{conn: conn} do
    {:ok, two_factor_user} =
      user_fixture()
      |> Recognizer.Repo.preload(:notification_preference)
      |> Accounts.update_user_two_factor(%{two_factor_enabled: true})

    %{
      conn: Phoenix.ConnTest.init_test_session(conn, %{current_user: two_factor_user}),
      user: two_factor_user
    }
  end

  describe "GET /two_factor" do
    test "renders the two factor input page", %{conn: conn} do
      conn = get(conn, Routes.user_two_factor_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Security Code</h2>"
    end
  end

  describe "POST /two_factor" do
    test "redirects to user settings for successful security codes", %{conn: conn, user: user} do
      token = Authentication.generate_token(user)
      conn = post(conn, Routes.user_two_factor_path(conn, :create), %{"user" => %{"two_factor_code" => token}})
      assert redirected_to(conn) == "/settings"
    end

    test "emits error message with invalid security code", %{conn: conn} do
      conn =
        post(conn, Routes.user_two_factor_path(conn, :create), %{
          "user" => %{"token" => "INVALID"}
        })

      assert redirected_to(conn) == "/two_factor"
      assert get_flash(conn, :error) =~ "Invalid"
    end
  end

  describe "POST /two_factor/resend" do
    test "redirects with flash message", %{conn: conn} do
      conn = post(conn, Routes.user_two_factor_path(conn, :resend))

      assert redirected_to(conn) == "/two_factor"
      assert get_flash(conn, :info) =~ "resent"
    end
  end
end

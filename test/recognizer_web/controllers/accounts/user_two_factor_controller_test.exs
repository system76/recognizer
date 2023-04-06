defmodule RecognizerWeb.Accounts.UserTwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  alias RecognizerWeb.Authentication

  setup %{conn: conn} do
    user = :user |> build() |> add_two_factor() |> insert()

    %{
      conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          two_factor_user_id: user.id
        }),
      user: user
    }
  end

  defp new_user_conn() do
    conn = Phoenix.ConnTest.build_conn()
    user = :user |> build() |> add_two_factor() |> insert()

    Phoenix.ConnTest.init_test_session(conn, %{
      two_factor_user_id: user.id
    })
  end

  describe "GET /two-factor" do
    test "renders the two factor input page", %{conn: conn} do
      conn = get(conn, Routes.user_two_factor_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Security Code</h2>"
    end
  end

  describe "POST /two-factor" do
    test "redirects to user settings for successful security codes", %{conn: conn, user: user} do
      token = Authentication.generate_token(user)
      conn = post(conn, Routes.user_two_factor_path(conn, :create), %{"user" => %{"two_factor_code" => token}})
      assert redirected_to(conn) == "/settings"
    end

    test "emits error message with invalid security code", %{conn: conn} do
      conn =
        post(conn, Routes.user_two_factor_path(conn, :create), %{
          "user" => %{"two_factor_code" => "INVALID"}
        })

      assert redirected_to(conn) == "/two-factor"
      assert get_flash(conn, :error) =~ "Invalid"
    end
  end

  describe "POST /two-factor/resend" do
    test "redirects with flash message", %{conn: conn} do
      conn = post(conn, Routes.user_two_factor_path(conn, :resend))

      assert redirected_to(conn) == "/two-factor"
      assert get_flash(conn, :info) =~ "resent"
    end

    test "rate limited", %{conn: conn} do
      Enum.each(0..20, fn _ -> post(conn, Routes.user_two_factor_path(conn, :resend)) end)
      conn = post(conn, Routes.user_two_factor_path(conn, :resend))

      assert response(conn, 429)
    end

    test "rate limited only by user id", %{conn: conn} do
      Enum.each(0..20, fn _ ->
        c = new_user_conn()
        post(c, Routes.user_two_factor_path(c, :resend))
      end)

      conn = post(conn, Routes.user_two_factor_path(conn, :resend))

      assert redirected_to(conn) == "/two-factor"
      assert get_flash(conn, :info) =~ "resent"
    end
  end
end

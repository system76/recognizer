defmodule RecognizerWeb.AuthenticationTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountsFixtures

  alias RecognizerWeb.Authentication

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, RecognizerWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: insert(:user), conn: conn}
  end

  describe "log_in_user/3" do
    test "stores the user session", %{conn: conn, user: user} do
      conn = Authentication.log_in_user(conn, user)
      assert redirected_to(conn) == "/settings"
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn = conn |> put_session(:to_be_removed, "value") |> Authentication.log_in_user(user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to change password prompt if organization requirement", %{conn: conn} do
      user =
        :user
        |> build(inserted_at: NaiveDateTime.add(NaiveDateTime.utc_now(), -999_999, :second))
        |> add_organization_policy(password_expiration: 1)
        |> insert()

      conn = conn |> Authentication.log_in_user(user)
      assert redirected_to(conn) == "/prompt/update-password"
    end

    test "redirects to two factor prompt if organization requirement", %{conn: conn} do
      user =
        :user
        |> build()
        |> add_organization_policy(two_factor_required: true)
        |> insert()

      conn = conn |> Authentication.log_in_user(user)
      assert redirected_to(conn) == "/prompt/setup-two-factor"
    end

    test "redirects to the configured path", %{conn: conn, user: user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> Authentication.log_in_user(user)
      assert redirected_to(conn) == "/hello"
    end
  end

  describe "logout_user/1" do
    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> Authentication.log_out_user()
      assert redirected_to(conn) == "/"
    end
  end
end

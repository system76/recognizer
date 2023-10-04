defmodule RecognizerWeb.Accounts.UserRegistrationControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Create Account</h2>"
      assert response =~ "Log in</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(insert(:user)) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/settings"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and prompts for verification", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      refute Recognizer.Guardian.Plug.current_resource(conn)
      assert redirected_to(conn) =~ "/prompt/verification"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short", "first_name" => "<>"}
        })

      response = html_response(conn, 200)
      assert response =~ "Create Account</h2>"
      assert response =~ "must have the @ sign, no spaces and a top level domain"
      assert response =~ "must contain a number"
      assert response =~ "must not contain special characters"
    end

    test "rate limits account creation", %{conn: conn} do
      Enum.each(0..20, fn _ ->
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })
      end)

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      refute Recognizer.Guardian.Plug.current_resource(conn)
      assert response(conn, 429)
    end
  end
end

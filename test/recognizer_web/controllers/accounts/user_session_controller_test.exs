defmodule RecognizerWeb.Accounts.UserSessionControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  setup do
    two_factor_user = :user |> build() |> add_two_factor() |> insert()

    %{
      user: insert(:user),
      two_factor_user: two_factor_user
    }
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Log In</h2>"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/settings"
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => user.password}
        })

      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => user.password
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "logs the user in and redirects to two factor page", %{conn: conn, two_factor_user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => user.password}
        })

      assert redirected_to(conn) == Routes.user_two_factor_path(conn, :new)
    end

    test "emits message when logging into an account with no password", %{conn: conn} do
      user = insert(:user, password: nil)
      _oauth = insert(:oauth, user_id: user.id)

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => ""}
        })

      response = html_response(conn, 200)
      assert response =~ "Log In</h2>"
      assert response =~ "It looks like this account was setup with third-party login"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log In</h2>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
    end

    test "redirects if the redirect_uri is given", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.user_session_path(conn, :delete, %{
            "redirect_uri" => "http://localhost:3000/logged-out"
          })
        )

      assert redirected_to(conn) == "http://localhost:3000/logged-out"
    end
  end
end

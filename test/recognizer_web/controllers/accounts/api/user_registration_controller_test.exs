defmodule RecognizerWeb.Api.UserRegistrationControllerTest do
  use RecognizerWeb.ConnCase

  alias Recognizer.Accounts.User
  alias Recognizer.Repo

  setup :register_and_log_in_admin

  describe "POST /api/create-account" do
    test "POST /api/create-account is limited to staff only", %{conn: conn} do
      conn =
        post(conn, "/api/create-account", %{
          "user" => %{
            "email" => "test@example.com",
            "first_name" => "Test",
            "last_name" => "User"
          }
        })

      assert %{"user" => _} = json_response(conn, 201)
    end

    test "POST /api/create-account verifies the user", %{conn: conn} do
      email = "test-verification@example.com"

      conn =
        post(conn, "/api/create-account", %{
          "user" => %{
            "email" => email,
            "first_name" => "Test",
            "last_name" => "User"
          }
        })

      assert %{"user" => _} = json_response(conn, 201)
      assert %User{verified_at: verified_at} = Repo.get_by!(User, email: email)
      assert verified_at != nil
    end

    test "POST /api/create-account fails for regular users", %{conn: conn} do
      conn =
        %{conn: conn}
        |> register_and_log_in_user()
        |> Map.get(:conn)
        |> Plug.Conn.put_req_header("accept", "application/json")
        |> post("/api/create-account", %{
          "user" => %{
            "email" => "test@example.com",
            "first_name" => "Test",
            "last_name" => "User"
          }
        })

      assert json_response(conn, 401)
    end
  end
end

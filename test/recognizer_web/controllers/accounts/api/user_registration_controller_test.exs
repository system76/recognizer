defmodule RecognizerWeb.Api.UserRegistrationControllerTest do
  use RecognizerWeb.ConnCase

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

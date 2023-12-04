defmodule RecognizerWeb.Api.UserRegistrationControllerTest do
  use RecognizerWeb.ConnCase

  import Mox

  alias Recognizer.Accounts.BCCustomerUser
  alias Recognizer.Accounts.User
  alias Recognizer.Repo

  @moduletag capture_log: true

  setup :verify_on_exit!
  setup :register_and_log_in_admin

  defp ok_bigcommerce_response() do
    body = Jason.encode!(%{data: [%{id: 1001}]})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}}
  end

  defp limit_bigcommerce_response() do
    headers = [{"x-rate-limit-time-reset-ms", "1"}]

    {:ok, %HTTPoison.Response{status_code: 429, headers: headers}}
  end

  describe "POST /api/create-account" do
    test "POST /api/create-account is limited to staff only", %{conn: conn} do
      user = %{
        "email" => "test@example.com",
        "first_name" => "Test",
        "last_name" => "User"
      }

      user_json = Jason.encode!([user])

      expect(HTTPoisonMock, :post, 1, fn _, ^user_json, _ -> ok_bigcommerce_response() end)

      conn = post(conn, "/api/create-account", %{"user" => user})

      assert %{"user" => _} = json_response(conn, 201)
      assert Repo.get_by(BCCustomerUser, bc_id: 1001)
    end

    test "POST /api/create-account verifies the user", %{conn: conn} do
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> ok_bigcommerce_response() end)

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

    test "POST /api/create-account retries on rate limit", %{conn: conn} do
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> limit_bigcommerce_response() end)
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> ok_bigcommerce_response() end)

      email = "test-limit@example.com"

      conn =
        post(conn, "/api/create-account", %{
          "user" => %{
            "email" => email,
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

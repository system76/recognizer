defmodule RecognizerWeb.AccountControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.Factories
  import RecognizerWeb.AuthHelper

  setup do
    %{id: _id} = audience = insert(:audience)
    {:ok, [conn: api_request(build_conn(), audience)]}
  end

  describe "create/2" do
    test "returns a 201 and the newly created resource", %{conn: conn} do
      %{"email" => email, "first_name" => first_name} =
        body =
        :user
        |> string_params_for()
        |> Map.put("password", "p@ssw0Rd!")
        |> Map.put("password_confirmation", "p@ssw0Rd!")

      %{
        "email" => ^email,
        "first_name" => ^first_name
      } =
        conn
        |> post("/accounts", Jason.encode!(body))
        |> json_response(201)
    end
  end

  describe "show/2" do
    test "returns a 200 and the requested resource for authenticated requests", %{conn: conn} do
      %{email: email, first_name: first, last_name: last} = user = insert(:user)

      assert %{
               "email" => ^email,
               "first_name" => ^first,
               "last_name" => ^last
             } =
               conn
               |> login(user)
               |> get("/me")
               |> json_response(200)
    end

    test "returns a 401 for unauthenticated requests", %{conn: conn} do
      conn
      |> get("/me")
      |> json_response(401)
    end
  end

  describe "update/2" do
    test "returns a 201 and the newly created resource for authenticated requests", %{conn: conn} do
      user = insert(:user)

      updates = %{
        first_name: "Changed"
      }

      assert %{"first_name" => "Changed"} =
               conn
               |> login(user)
               |> patch("/me", Jason.encode!(updates))
               |> json_response(200)
    end

    test "returns a 401 for unauthenticated requests", %{conn: conn} do
      conn
      |> patch("/me", Jason.encode!(%{}))
      |> json_response(401)
    end
  end
end

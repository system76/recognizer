defmodule RecognizerWeb.AuthControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.Factories

  alias Recognizer.Auth

  setup do
    %{id: audience_id, token: audience_token} = insert(:audience)
    %{email: email} = insert(:user)

    {:ok, [audience_id: audience_id, audience_token: audience_token, email: email]}
  end

  describe "exchange/2" do
    test "returns a 201 with access and refresh tokens", %{
      audience_id: audience_id,
      audience_token: audience_token,
      conn: conn,
      email: email
    } do
      {:ok, old_access_token, refresh_token} = Auth.login(email, "password", audience_id)

      assert %{
               "access_token" => new_access_token,
               "refresh_token" => ^refresh_token
             } =
               conn
               |> put_req_header("x-recognizer-token", audience_token)
               |> put_req_header("content-type", "application/json")
               |> post("/auth/exchange", Jason.encode!(%{token: refresh_token}))
               |> json_response(201)

      assert new_access_token != old_access_token
    end

    test "returns a 401 when unable to exchange tokens", %{
      audience_token: audience_token,
      conn: conn,
      email: email
    } do
      %{id: another_audience_id} = insert(:audience)

      {:ok, _access_token, refresh_token} = Auth.login(email, "password", another_audience_id)

      conn
      |> put_req_header("x-recognizer-token", audience_token)
      |> put_req_header("content-type", "application/json")
      |> post("/auth/exchange", Jason.encode!(%{token: refresh_token}))
      |> json_response(401)
    end
  end

  describe "login/2" do
    test "returns a 201 with access and refresh tokens", %{
      audience_token: audience_token,
      conn: conn,
      email: email
    } do
      json_body = Jason.encode!(%{email: email, password: "password"})

      assert %{
               "access_token" => access_token,
               "refresh_token" => refresh_token
             } =
               conn
               |> put_req_header("x-recognizer-token", audience_token)
               |> put_req_header("content-type", "application/json")
               |> post("/auth/login", json_body)
               |> json_response(201)

      refute is_nil(access_token)
      refute is_nil(refresh_token)
    end

    test "returns a 401 when invalid credentials", %{
      audience_token: audience_token,
      email: email,
      conn: conn
    } do
      json_body = Jason.encode!(%{email: email, password: "wrong password"})

      conn
      |> put_req_header("x-recognizer-token", audience_token)
      |> put_req_header("content-type", "application/json")
      |> post("/auth/login", json_body)
      |> json_response(401)
    end
  end
end

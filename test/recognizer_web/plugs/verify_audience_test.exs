defmodule RecognizerWeb.Plugs.VerifyAudienceTest do
  use RecognizerWeb.ConnCase

  import Recognizer.Factories

  alias RecognizerWeb.Plugs.VerifyAudience

  @opts VerifyAudience.init([])

  test "passes through the conn when a valid x-recognizer-token is found", %{conn: conn} do
    %{token: token} = insert(:audience)

    %Plug.Conn{state: state} =
      conn
      |> put_req_header("x-recognizer-token", token)
      |> VerifyAudience.call(@opts)

    refute :sent == state
  end

  test "returns a 401 when missing the x-recognizer-token", %{conn: conn} do
    assert %Plug.Conn{state: :sent, status: 401} = VerifyAudience.call(conn, @opts)
  end

  test "returns a 401 when x-recognizer-token is invalid", %{conn: conn} do
    assert %Plug.Conn{state: :sent, status: 401} =
             conn
             |> put_req_header("x-recognizer-token", "not a valid token")
             |> VerifyAudience.call(@opts)
  end
end

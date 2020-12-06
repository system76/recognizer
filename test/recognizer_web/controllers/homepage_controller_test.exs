defmodule RecognizerWeb.HomePageControllerTest do
  use RecognizerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "System76"
  end
end

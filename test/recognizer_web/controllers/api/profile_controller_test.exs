defmodule RecognizerWeb.Api.ProfileControllerTest do
  use RecognizerWeb.ConnCase

  describe "GET /api/profile" do
    setup [:register_and_log_in_user]

    test "GET /api/profile", %{conn: conn, user: %{id: user_id}} do
      conn = get(conn, "/api/profile")
      assert %{"id" => ^user_id} = json_response(conn, 200)
    end
  end
end

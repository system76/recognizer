defmodule RecognizerWeb.AuthHelper do
  @moduledoc """
  Helper functions for working with authenticated HTTP requests
  """

  import Plug.Conn

  alias Recognizer.Guardian

  @doc """
  A helper function for adding an Audience Token and Content-Type to a connection
  """
  def api_request(conn, %{token: audience_token}) do
    conn
    |> put_req_header("x-recognizer-token", audience_token)
    |> put_req_header("content-type", "application/json")
  end

  @doc """
  A helper for logging in a User and updating the request headers accordingly
  """
  def login(conn, user) do
    {:ok, access_token, _claims} =
      Guardian.encode_and_sign(user, %{scope: []}, token_type: "access", ttl: {7, :days})

    put_req_header(conn, "authorization", "bearer #{access_token}")
  end
end

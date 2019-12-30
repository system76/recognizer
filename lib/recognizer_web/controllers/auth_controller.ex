defmodule RecognizerWeb.AuthController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.FallbackController
  alias Recognizer.Auth

  action_fallback FallbackController

  def access_token(conn, %{"data" => %{"email" => email, "password" => password}}) do
    with {:ok, audience_token} <- audience_token(conn),
         {:ok, access, refresh} <- Auth.login(email, password, audience_token) do
      render(conn, "tokens.json", access_token: access, refresh_token: refresh)
    end
  end

  def login(_conn, _params) do
    {:error, :missing_required_fields}
  end

  def exchange(conn, %{"data" => %{"token" => refresh_token}}) do
    with {:ok, audience_token} <- audience_token(conn),
         {:ok, access, refresh} <- Auth.exchange(refresh_token, audience_token) do
      render(conn, "tokens.json", access_token: access, refresh_token: refresh)
    end
  end

  def verify(conn, %{"data" => %{"token" => token}}) do
    with {:ok, _claims} <- Auth.decode_and_verify(token) do
      send_resp(conn, 202, "")
    end
  end

  def verify(_conn, _params) do
    {:error, :missing_required_fields}
  end

  defp audience_token(conn) do
    with [token] <- Plug.Conn.get_req_header(conn, "x-recognizer-token") do
      {:ok, token}
    else
      _ -> {:error, "missing or invalid api token"}
    end
  end
end

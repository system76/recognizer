defmodule RecognizerWeb.OauthProvider.TokenController do
  use RecognizerWeb, :controller

  alias ExOauth2Provider.Token

  @one_minute 60_000

  # Rate limit: 100 requests per minute per IP+client combination
  # Protects against brute force attacks while allowing legitimate OAuth clients
  plug Hammer.Plug,
       [
         rate_limit: {"oauth:token", @one_minute, 100},
         by: {:conn, &__MODULE__.get_rate_limit_key/1}
       ]
       when action in [:create]

  # Rate limit: 10 requests per minute per IP for invalid OAuth paths
  # Protects against endpoint scanning attacks (e.g., /oauth/.env, /oauth/auth.json)
  plug Hammer.Plug,
       [
         rate_limit: {"oauth:invalid", @one_minute, 10},
         by: {:conn, &__MODULE__.get_remote_ip/1}
       ]
       when action in [:not_found]

  def get_rate_limit_key(conn) do
    ip = get_remote_ip(conn)
    client_id = conn.params["client_id"] || "unknown"
    "#{ip}:#{client_id}"
  end

  def get_remote_ip(conn) do
    # Get real IP from X-Forwarded-For or remote IP
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip |> String.split(",") |> List.first() |> String.trim()
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  def create(conn, params) do
    case Token.grant(params, otp_app: :recognizer) do
      {:ok, access_token} ->
        json(conn, access_token)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  # Handle non-POST methods for /oauth/token
  def method_not_allowed(conn, _params) do
    conn
    |> put_resp_header("allow", "POST")
    |> put_status(:method_not_allowed)
    |> json(%{
      "error" => "invalid_request",
      "error_description" => "The token endpoint only supports POST"
    })
  end

  # Handle invalid OAuth endpoint requests (e.g., /oauth/.env, /oauth/auth.json)
  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{
      "error" => "invalid_request",
      "error_description" => "The requested OAuth endpoint does not exist"
    })
  end
end

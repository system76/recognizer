defmodule RecognizerWeb.OauthProvider.TokenController do
  use RecognizerWeb, :controller

  alias ExOauth2Provider.Token

  @one_minute 60_000

  # Rate limit: 30 requests per minute per IP for token endpoint
  plug Hammer.Plug,
       [
         rate_limit: {"oauth:token", @one_minute, 30},
         by: {:conn, &__MODULE__.get_remote_ip/1}
       ]
       when action in [:create]

  # Rate limit: 10 requests per minute per IP for invalid endpoints
  plug Hammer.Plug,
       [
         rate_limit: {"oauth:invalid", @one_minute, 10},
         by: {:conn, &__MODULE__.get_remote_ip/1}
       ]
       when action in [:not_found, :method_not_allowed]

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

  # Handle non-existent OAuth endpoints
  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{
      "error" => "invalid_request",
      "error_description" => "The requested OAuth endpoint does not exist"
    })
  end
end

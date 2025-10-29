defmodule RecognizerWeb.OauthProvider.TokenController do
  use RecognizerWeb, :controller

  alias ExOauth2Provider.Token

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

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
end

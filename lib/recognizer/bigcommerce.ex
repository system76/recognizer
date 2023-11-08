defmodule Recognizer.BigCommerce do
  require Logger

  alias Recognizer.BigCommerce.Token

  def generate_login_jwt(user) do
    {:ok, token, claims} =
      user
      |> jwt_claims()
      |> Token.generate_and_sign(jwt_signer())

    IO.inspect(claims)

    token
  end

  def login_redirect_uri(jwt) do
    config(:login_uri) <> jwt
  end

  defp jwt_claims(user) do
    %{
      "iss" => config(:client_id),
      "jti" => 'some-unique-token-id',
      "operation" => 'customer_login',
      "store_hash" => config(:store_hash),
      "customer_id" => user.bigcommerce_user.bc_id
    }
  end

  defp jwt_signer() do
    Joken.Signer.create("HS256", config(:client_secret))
  end

  defp config(key) do
    Application.get_env(:recognizer, __MODULE__)[key]
  end
end

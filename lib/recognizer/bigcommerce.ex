defmodule Recognizer.BigCommerce do
  @moduledoc """
  BigCommerce context.
  """

  require Logger

  alias Recognizer.Accounts.BCCustomerUser, as: Customer
  alias Recognizer.BigCommerce.Client
  alias Recognizer.BigCommerce.Token
  alias Recognizer.Repo

  def enabled?() do
    config(:enabled?)
  end

  def create_customer(user) do
    case Client.create_customer(user) do
      {:ok, bc_id} ->
        Repo.insert(%Customer{user_id: user.id, bc_id: bc_id})
        {:ok, user}

      {:error, e} ->
        Logger.error("error creating bigcommerce customer: #{inspect(e)}")
        {:error, e}
    end
  end

  def generate_login_jwt(user) do
    {:ok, token, _claims} =
      user
      |> Recognizer.Repo.preload(:bigcommerce_user)
      |> jwt_claims()
      |> Token.generate_and_sign(jwt_signer())

    token
  end

  def login_redirect_uri(jwt) do
    config(:login_uri) <> jwt
  end

  defp jwt_claims(user) do
    %{
      "aud" => "BigCommerce",
      "iss" => config(:client_id),
      "jti" => Ecto.UUID.generate(),
      "operation" => "customer_login",
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

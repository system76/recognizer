defmodule Recognizer.BigCommerce.Client do
  @moduledoc """
  BigCommerce v3
  """

  require Logger

  alias Recognizer.Accounts.User

  alias HTTPoison.Response

  def create_customer(user) do
    with {:ok, customer_params} <- user_as_customer_params(user),
         {:ok, customer_json} <- Jason.encode(customer_params),
         {:ok, response} <- post_customer(customer_json) do
      get_id(response)
    else
      {:error, e} ->
        Logger.error("cannot create customer with error: #{inspect(e)}")
        {:error, e}

      e ->
        Logger.error("cannot create customer with error: #{inspect(e)}")
        {:error, e}
    end
  end

  defp user_as_customer_params(%User{email: email, first_name: first_name, last_name: last_name}) do
    {:ok,
     %{
       "email" => email,
       "first_name" => first_name,
       "last_name" => last_name
     }}
  end

  defp user_as_customer_params(_user) do
    {:error, :invalid_user}
  end

  defp post_customer(customer_json) do
    case http_client().post(customers_uri(), customer_json, default_headers()) do
      {:ok, %Response{body: response, status_code: 200}} -> {:ok, response}
      {:error, e} -> {:error, e}
      e -> {:error, e}
    end
  end

  defp get_id(response) do
    case Jason.decode(response) do
      {:ok, %{"data" => %{"id" => id}}} -> {:ok, id}
      {:error, e} -> {:error, e}
      e -> {:error, e}
    end
  end

  defp default_headers() do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"Authorization", "Bearer #{config(:access_token)}"},
      {"x-Auth-Token", config(:access_token)}
    ]
  end

  defp customers_uri() do
    uri("/v3/customers")
  end

  defp uri(path) do
    "https://api.bigcommerce.com/stores/#{config(:store_hash)}#{path}"
  end

  defp http_client() do
    config(:http_client)
  end

  defp config(key) do
    Application.get_env(:recognizer, Recognizer.BigCommerce)[key]
  end
end

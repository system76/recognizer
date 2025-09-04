defmodule Recognizer.BigCommerce.Client do
  @moduledoc """
  BigCommerce v3
  """

  require Logger

  alias Recognizer.Accounts.BCCustomerUser
  alias Recognizer.Accounts.User

  alias HTTPoison.Response

  @default_retry_ms 5000

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

  def update_customer(user) do
    with {:ok, customer_params} <- user_as_customer_params(user),
         {:ok, customer_json} <- Jason.encode(customer_params) do
      put_customer(customer_json)
    else
      {:error, e} ->
        Logger.error("cannot update customer with error: #{inspect(e)}")
        {:error, e}

      e ->
        Logger.error("cannot update customer with error: #{inspect(e)}")
        {:error, e}
    end
  end

  defp post_customer(customer_json) do
    case http_client().post(customers_uri(), customer_json, default_headers()) do
      {:ok, %Response{body: response, status_code: 200}} ->
        {:ok, response}

      {:ok, %Response{status_code: 422, body: body}} ->
        handle_422_error(body, "create")

      {:ok, %Response{status_code: 429, headers: headers}} ->
        sleep_for_rate_limit(headers)
        post_customer(customer_json)

      {:error, e} ->
        {:error, e}

      e ->
        {:error, e}
    end
  end

  defp put_customer(customer_json) do
    case http_client().put(customers_uri(), customer_json, default_headers()) do
      {:ok, %Response{body: response, status_code: 200}} ->
        {:ok, response}

      {:ok, %Response{status_code: 422, body: body}} ->
        handle_422_error(body, "update")

      {:ok, %Response{status_code: 429, headers: headers}} ->
        sleep_for_rate_limit(headers)
        put_customer(customer_json)

      {:error, e} ->
        {:error, e}

      e ->
        {:error, e}
    end
  end

  # Precisely analyze 422 errors to determine if it's email duplication
  defp handle_422_error(body, operation) do
    case Jason.decode(body) do
      {:ok, %{"errors" => %{".customer_update" => error}}} when is_binary(error) ->
        if String.contains?(String.downcase(error), "email") and
             String.contains?(String.downcase(error), "already in use") do
          Logger.info("BigCommerce customer #{operation}: email already exists, treating as success - #{error}")
          {:ok, :email_already_exists}
        else
          Logger.error("BigCommerce customer #{operation} failed with validation error: #{error}")
          {:error, {:validation_error, error}}
        end

      {:ok, %{"errors" => errors}} ->
        Logger.error("BigCommerce customer #{operation} failed with errors: #{inspect(errors)}")
        {:error, {:validation_errors, errors}}

      {:ok, decoded} ->
        Logger.error("BigCommerce customer #{operation} failed with unexpected 422 response: #{inspect(decoded)}")
        {:error, {:unexpected_422, decoded}}

      {:error, json_error} ->
        Logger.error(
          "BigCommerce customer #{operation} failed with unparseable 422 response: #{body}, JSON error: #{inspect(json_error)}"
        )

        {:error, {:unparseable_422, body}}
    end
  end

  def get_customers(queries \\ []) do
    with params <- customer_queries_as_params(queries),
         full_uri <- customers_uri(),
         headers <- default_headers(),
         :ok <- Logger.debug("GET bigcommerce customers by params: #{inspect(params)}"),
         {:ok, %Response{body: response, status_code: 200}} <-
           http_client().get(full_uri, headers, params: params),
         {:ok, %{"data" => customers}} <- Jason.decode(response),
         customer_ids <- Enum.map(customers, fn %{"id" => id} -> id end) do
      {:ok, customer_ids}
    else
      {:ok, %Response{status_code: 429, headers: headers}} ->
        sleep_for_rate_limit(headers)
        get_customers(queries)

      {:ok, %Response{status_code: 503}} ->
        sleep_for_rate_limit(@default_retry_ms)
        get_customers(queries)

      {_, %Response{body: body, status_code: code}} ->
        Logger.error("Unexpected http response #{inspect(code)}: #{inspect(body)}")
        {:error, code}

      e ->
        Logger.error("cannot get customers with error: #{inspect(e)}")
        {:error, e}
    end
  end

  defp customer_queries_as_params(queries) do
    []
    |> Keyword.merge(
      case Keyword.get(queries, :emails) do
        nil -> []
        [] -> []
        emails -> [{"email:in", Enum.join(emails, ",")}]
      end
    )
    |> Keyword.merge(
      case Keyword.get(queries, :ids) do
        nil -> []
        [] -> []
        ids -> [{"id:in", Enum.join(ids, ",")}]
      end
    )
  end

  defp get_id(response) do
    case response do
      :email_already_exists ->
        # If email already exists, return special response for upper level handling
        {:ok, :email_already_exists}

      _ ->
        case Jason.decode(response) do
          {:ok, %{"data" => [%{"id" => id}]}} -> {:ok, id}
          {:error, e} -> {:error, e}
          e -> {:error, e}
        end
    end
  end

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, _key, ""), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp put_if_not_nil(map, _key, nil), do: map
  defp put_if_not_nil(map, key, value), do: Map.put(map, key, value)

  defp user_as_customer_params(%User{
         email: email,
         first_name: first_name,
         last_name: last_name,
         company_name: company,
         phone_number: phone_number,
         bigcommerce_user: %BCCustomerUser{bc_id: bc_id}
       }) do
    base =
      %{
        "id" => bc_id,
        "email" => email,
        "first_name" => first_name,
        "last_name" => last_name,
        "company" => company
      }
      |> put_if_not_nil("phone", phone_number)

    {:ok, [base]}
  end

  defp user_as_customer_params(%User{
         email: email,
         first_name: first_name,
         last_name: last_name,
         company_name: company,
         phone_number: phone_number
       }) do
    base =
      %{
        "email" => email,
        "first_name" => first_name,
        "last_name" => last_name,
        "company" => company
      }
      |> put_if_not_nil("phone", phone_number)

    {:ok, [base]}
  end

  defp user_as_customer_params(_user) do
    {:error, :invalid_user}
  end

  defp default_headers do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"Authorization", "Bearer #{config(:access_token)}"},
      {"x-Auth-Token", config(:access_token)}
    ]
  end

  defp customers_uri do
    uri("/v3/customers")
  end

  defp uri(path) do
    "https://api.bigcommerce.com/stores/#{config(:store_hash)}#{path}"
  end

  defp http_client do
    config(:http_client)
  end

  defp config(key) do
    Application.get_env(:recognizer, Recognizer.BigCommerce)[key]
  end

  defp sleep_for_rate_limit(headers) when is_list(headers) do
    retry_ms =
      case List.keyfind(headers, "x-rate-limit-time-reset-ms", 0) do
        nil -> @default_retry_ms
        {_, retry_value} -> String.to_integer(retry_value)
      end

    Logger.warn("Rate limited, sleeping for ms: #{inspect(retry_ms)}")
    Process.sleep(retry_ms)
  end

  defp sleep_for_rate_limit(ms) when is_integer(ms) do
    Logger.warn("Service unavailable, sleeping for ms: #{inspect(ms)}")
    Process.sleep(ms)
  end
end

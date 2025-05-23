defmodule Recognizer.BigCommerce.Client do
  @moduledoc """
  BigCommerce v3
  """

  require Logger

  alias Recognizer.Accounts.User

  alias HTTPoison.Response

  @default_retry_ms 5000

  def create_customer(user) do
    with {:ok, customer_params} <- user_as_customer_params_for_create(user),
         {:ok, customer_json} <- Jason.encode(customer_params),
         {:ok, response_body} <- post_customer_to_bc(customer_json) do
      get_id_from_response(response_body)
    else
      {:error, e} ->
        Logger.error("cannot create customer with error: #{inspect(e)}")
        {:error, e}
    end
  end

  def update_customer(user) do
    with {:ok, bc_id} <- get_bc_id_for_update(user),
         {:ok, customer_params_list} <- user_as_customer_params_for_update(user, bc_id),
         {:ok, customer_params} <- safe_get_head(customer_params_list),
         {:ok, customer_json} <- Jason.encode(customer_params),
         {:ok, _response_body} <- put_customer_to_bc(customer_json) do
      :ok
    else
      {:error, :missing_bc_id_for_update} ->
        Logger.error("BigCommerce user ID not found for update: #{inspect(user)}")
        {:error, :missing_bc_id_for_update}

      {:error, e} ->
        Logger.error("Failed during BigCommerce customer update steps: #{inspect(e)}")
        {:error, e}
    end
  end

  defp get_bc_id_for_update(user) do
    bc_user = user.bigcommerce_user

    if is_nil(bc_user) || is_nil(bc_user.bc_id) do
      {:error, :missing_bc_id_for_update}
    else
      {:ok, bc_user.bc_id}
    end
  end

  defp safe_get_head([head | _tail]), do: {:ok, head}
  defp safe_get_head(_), do: {:error, :invalid_customer_params_format_not_list_with_head}

  defp post_customer_to_bc(customer_json) do
    case http_client().post(customers_uri_for_create_or_list(), customer_json, default_headers()) do
      {:ok, %Response{body: response_body, status_code: status_code}} when status_code in [200, 201] ->
        {:ok, response_body}

      {:ok, %Response{body: error_body, status_code: status_code}} ->
        handle_api_error("create", status_code, error_body)

      {:error, %HTTPoison.Error{reason: reason}} = http_error ->
        handle_http_client_error("create", reason, http_error)

      e ->
        handle_unexpected_response("create", e)
    end
  end

  defp put_customer_to_bc(customer_json) do
    case http_client().put(customers_uri_for_create_or_list(), "[#{customer_json}]", default_headers()) do
      {:ok, %Response{body: response_body, status_code: 200}} ->
        {:ok, response_body}

      {:ok, %Response{body: error_body, status_code: status_code}} ->
        handle_api_error("update", status_code, error_body)

      {:error, %HTTPoison.Error{reason: reason}} = http_error ->
        handle_http_client_error("update", reason, http_error)

      e ->
        handle_unexpected_response("update", e)
    end
  end

  def get_customers(queries \\ []) do
    with params <- customer_queries_as_params(queries),
         full_uri <- customers_uri_for_create_or_list(),
         headers <- default_headers(),
         :ok <- Logger.debug("GET bigcommerce customers by params: #{inspect(params)}"),
         {:ok, %Response{body: response, status_code: 200}} <-
           http_client().get(full_uri <> "?#{URI.encode_query(params)}", headers),
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

      {:ok, %Response{body: error_body, status_code: status_code}} ->
        handle_api_error("get", status_code, error_body)

      {:error, %HTTPoison.Error{reason: reason}} = http_error ->
        handle_http_client_error("get", reason, http_error)

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

  defp get_id_from_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, %{"data" => [%{"id" => id}]}} ->
        {:ok, id}

      {:ok, %{"data" => %{"id" => id}}} ->
        {:ok, id}

      {:error, e} ->
        Logger.error("Failed to decode ID from BigCommerce response: #{inspect(e)}, Body: #{inspect(response_body)}")
        {:error, {:id_decode_error, e}}

      e ->
        Logger.error(
          "Unexpected format in BigCommerce response when extracting ID: #{inspect(e)}, Body: #{inspect(response_body)}"
        )

        {:error, {:unexpected_id_format, e}}
    end
  end

  defp user_as_customer_params_for_create(%User{
         email: email,
         first_name: first_name,
         last_name: last_name,
         company_name: company,
         phone_number: phone_number
       }) do
    params = [
      %{
        "email" => email,
        "first_name" => first_name,
        "last_name" => last_name,
        "company" => company,
        "phone" => phone_number
      }
    ]

    {:ok, params}
  end

  defp user_as_customer_params_for_create(_user) do
    {:error, :invalid_user_for_bc_create_params}
  end

  defp user_as_customer_params_for_update(
         %User{
           email: email,
           first_name: first_name,
           last_name: last_name,
           company_name: company,
           phone_number: phone_number
         },
         bc_id
       )
       when not is_nil(bc_id) do
    params = [
      %{
        "id" => bc_id,
        "email" => email,
        "first_name" => first_name,
        "last_name" => last_name,
        "company" => company,
        "phone" => phone_number
      }
    ]

    {:ok, params}
  end

  defp user_as_customer_params_for_update(_user, _bc_id) do
    {:error, :invalid_user_or_bc_id_for_bc_update_params}
  end

  defp default_headers() do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"Authorization", "Bearer #{Application.get_env(:recognizer, Recognizer.BigCommerce)[:access_token]}"},
      {"x-Auth-Token", Application.get_env(:recognizer, Recognizer.BigCommerce)[:access_token]}
    ]
  end

  defp customers_uri_for_create_or_list() do
    uri("/v3/customers")
  end

  defp uri(path) do
    store_hash = Application.get_env(:recognizer, Recognizer.BigCommerce)[:store_hash]
    "https://api.bigcommerce.com/stores/#{store_hash}#{path}"
  end

  defp http_client() do
    Application.get_env(:recognizer, Recognizer.BigCommerce)[:http_client]
  end

  defp handle_api_error(action_type, status_code, error_body) do
    Logger.warn("BigCommerce customer #{action_type} API error. Status: #{status_code}, Body: #{inspect(error_body)}")

    decoded_body =
      case Jason.decode(error_body) do
        {:ok, decoded} -> decoded
        _ -> error_body
      end

    {:error, {:api_error, status_code, decoded_body}}
  end

  defp handle_http_client_error(action_type, reason, http_error) do
    Logger.error("BigCommerce customer #{action_type} HTTP client error: #{inspect(reason)}")
    http_error
  end

  defp handle_unexpected_response(action_type, error_event) do
    Logger.error("Unexpected response during BigCommerce customer #{action_type}: #{inspect(error_event)}")
    {:error, {:unexpected_response, error_event}}
  end

  defp sleep_for_rate_limit(headers) do
    retry_ms =
      case List.keyfind(headers, "x-rate-limit-time-reset-ms", 0) do
        nil -> @default_retry_ms
        {_, retry_value} -> String.to_integer(retry_value)
      end

    Logger.warn("Rate limited, sleeping for ms: #{inspect(retry_ms)}")
    Process.sleep(retry_ms)
  end
end

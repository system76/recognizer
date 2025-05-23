defmodule Recognizer.Hal do
  @moduledoc """
  A simple API client for the Hal API
  """
  require Logger

  def update_newsletter(nil) do
    Logger.error("update_newsletter/1 called with nil user")
    {:error, :nil_user_argument}
  end

  def update_newsletter(user) do
    with {:ok, validated_user} <- validate_user_data(user),
         {:ok, interests_url} <- build_url("/accounts/newsletter/interests"),
         {:ok, interests_response_body} <-
           fetch_data_with_retry(interests_url, "newsletter interests", Map.get(validated_user, :email)),
         {:ok, decoded_interests} <-
           decode_json(interests_response_body, "newsletter interests", Map.get(validated_user, :email)),
         groups <- calculate_interest_groups(decoded_interests, validated_user),
         {:ok, status_url} <- build_url("/accounts/newsletter?email_address=#{Map.get(validated_user, :email)}"),
         {:ok, status_response_body} <-
           fetch_data_with_retry(status_url, "newsletter status", Map.get(validated_user, :email)),
         {:ok, decoded_status} <-
           decode_json(status_response_body, "newsletter status", Map.get(validated_user, :email)),
         :update_allowed <- check_and_log_newsletter_status(decoded_status, Map.get(validated_user, :email)) do
      # Proceed to update the newsletter
      perform_newsletter_update(validated_user, groups)
    else
      # Handle any error from the with statement
      {:error, reason} ->
        Logger.error("Newsletter update failed for #{Map.get(user, :email, "unknown user")}: #{inspect(reason)}")
        # Return the specific error reason
        {:error, reason}

      :update_not_allowed ->
        # Logged in check_and_log_newsletter_status, so just return :ok or a specific atom
        :ok_not_updated

      _other_error ->
        # Catch-all for unexpected failures in `with`
        Logger.error("Unexpected error during newsletter update for #{Map.get(user, :email, "unknown user")}")
        {:error, :unexpected_error}
    end
  end

  # Validate user data
  defp validate_user_data(user) do
    if is_map(user) && !is_nil(Map.get(user, :email)) && !is_nil(Map.get(user, :newsletter)) do
      {:ok, user}
    else
      Logger.error(
        "update_newsletter/1 called with invalid user data (missing :email or :newsletter field): #{inspect(user)}"
      )

      {:error, :invalid_user_data}
    end
  end

  # 재시도 메커니즘을 가진 데이터 가져오기 함수
  defp fetch_data_with_retry(url, context_msg, email_for_log, retry_count \\ 3, retry_delay \\ 1000) do
    case fetch_data(url, context_msg, email_for_log) do
      {:ok, body} ->
        {:ok, body}

      {:error, reason} when retry_count > 0 ->
        Logger.warn("Retrying fetch for #{context_msg}, attempts left: #{retry_count - 1}")
        Process.sleep(retry_delay)
        fetch_data_with_retry(url, context_msg, email_for_log, retry_count - 1, retry_delay * 2)

      error ->
        error
    end
  end

  # Fetch data from HAL API
  defp fetch_data(url, context_msg, email_for_log) do
    case HTTPoison.get(url, authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error(
          "Failed to fetch #{context_msg} for #{email_for_log}. Status: #{status_code}, Body: #{inspect(error_body)}"
        )

        {:error, {:http_error, status_code, context_msg}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error fetching #{context_msg} for #{email_for_log}: #{inspect(reason)}")
        {:error, {:http_client_error, reason, context_msg}}
    end
  end

  # Decode JSON response
  defp decode_json(json_string, context_msg, email_for_log) do
    case Jason.decode(json_string) do
      {:ok, decoded_json} ->
        {:ok, decoded_json}

      {:error, Jason_decode_error} ->
        Logger.error(
          "Failed to decode #{context_msg} JSON for #{email_for_log}. Error: #{inspect(Jason_decode_error)}, Body: #{inspect(json_string)}"
        )

        {:error, {:json_decode_error, context_msg}}
    end
  end

  # Calculate interest groups
  defp calculate_interest_groups(decoded_interests_response, user) do
    raw_interests = Map.get(decoded_interests_response, "interests")
    interests = if is_list(raw_interests), do: raw_interests, else: []
    newsletter_status_value = Map.get(user, :newsletter)

    Enum.reduce(interests, %{}, fn item, acc ->
      atom_value = newsletter_status_value

      Map.put(acc, item["id"], atom_value)
    end)
  end

  # Check newsletter status and decide if update is allowed
  defp check_and_log_newsletter_status(decoded_status_response, email) do
    status = Map.get(decoded_status_response, "status")

    if status && Enum.member?(["pending", "subscribed"], status) do
      Logger.info("Newsletter status for #{email} is '#{status}', no update will be performed.")
      :update_not_allowed
    else
      # If status is nil, it might mean the user is not in the system yet, so allow update.
      # Or if status is something else, also allow update.
      Logger.info("Newsletter status for #{email} is '#{status || "nil"}', proceeding with update attempt.")
      # Explicitly return :update_allowed for clarity in `with`
      :update_allowed
    end
  end

  # Perform the actual newsletter update via POST
  defp perform_newsletter_update(user, groups) do
    with {:ok, email_address} <- validate_email_present(user),
         payload <- build_payload(email_address, user, groups),
         {:ok, post_url} <- build_url("/accounts/newsletter") do
      post_newsletter_with_retry(post_url, payload, email_address, 3)
    else
      # This else block will catch errors from validate_email_present or build_url
      {:error, reason} ->
        # Log if the reason is :missing_email_for_newsletter_update, otherwise it might be logged by build_url
        if reason == :missing_email_for_newsletter_update do
          Logger.error("Cannot perform newsletter update for user without email: #{inspect(user)}")
        end

        # Propagate the error
        {:error, reason}
    end
  end

  # 재시도 메커니즘을 가진 뉴스레터 POST 함수
  defp post_newsletter_with_retry(post_url, payload, email_address, retry_count, retry_delay \\ 1000) do
    case HTTPoison.post(post_url, payload, [{"content-type", "application/json"}] ++ authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Newsletter updated successfully for #{email_address}")
        :ok

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}}
      when retry_count > 0 and status_code >= 500 ->
        Logger.warn("Newsletter update failed with status #{status_code}, retrying. Attempts left: #{retry_count - 1}")
        Process.sleep(retry_delay)
        post_newsletter_with_retry(post_url, payload, email_address, retry_count - 1, retry_delay * 2)

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error(
          "Failed to update newsletter for #{email_address}. Status: #{status_code}, Body: #{inspect(error_body)}"
        )

        {:error, {:http_post_error, status_code}}

      {:error, %HTTPoison.Error{reason: reason}} when retry_count > 0 ->
        Logger.warn("HTTP error while posting newsletter update, retrying. Attempts left: #{retry_count - 1}")
        Process.sleep(retry_delay)
        post_newsletter_with_retry(post_url, payload, email_address, retry_count - 1, retry_delay * 2)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error while posting newsletter update for #{email_address}: #{inspect(reason)}")
        {:error, {:http_client_post_error, reason}}
    end
  end

  defp validate_email_present(user) do
    case Map.get(user, :email) do
      nil -> {:error, :missing_email_for_newsletter_update}
      email -> {:ok, email}
    end
  end

  defp build_payload(email_address, user, groups) do
    first_name = Map.get(user, :first_name, "")
    last_name = Map.get(user, :last_name, "")

    %{
      "email_address" => email_address,
      "status" => "pending",
      "interests" => groups,
      "merge_fields" => %{
        "FNAME" => first_name,
        "LNAME" => last_name
      }
    }
    # Assuming this encoding will not fail with validated data
    |> Jason.encode!()
  end

  defp build_url(path) do
    base_url = Application.get_env(:recognizer, :hal_url)

    if base_url do
      {:ok, Path.join([base_url, path])}
    else
      Logger.error("HAL service base_url is not configured.")
      {:error, :hal_base_url_not_configured}
    end
  end

  defp authorization_headers() do
    token = Application.get_env(:recognizer, :hal_token)

    if token do
      [{"authorization", "Recognizer #{token}"}]
    else
      Logger.error("HAL service authorization token is not configured.")
      # Or consider {:error, :hal_token_not_configured} if headers are mandatory
      []
    end
  end
end

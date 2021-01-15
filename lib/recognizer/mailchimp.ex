defmodule Recognizer.Mailchimp do
  @moduledoc """
  A simple API client for the Mailchimp API
  """

  require Logger

  alias Recognizer.Accounts.User

  @callback update_user(User.t()) :: {:ok, User.t()} | {:error, String.t()}

  def update_user(%User{} = user) do
    config = Application.get_env(:recognizer, :mailchimp)
    api_key = Keyword.get(config, :api_key)

    complete_url = mailchimp_user_url(user, config)
    hackney = [basic_auth: {"anystring", api_key}]

    body =
      user
      |> cast_user()
      |> Jason.encode!()

    case HTTPoison.put!(complete_url, body, %{"Content-type" => "application/json"}, hackney: hackney) do
      %{status: 200} -> {:ok, user}
      %{body: %{"detail" => reason}} -> {:error, reason}
      err -> {:error, inspect(err)}
    end
  end

  defp cast_user(%User{} = user) do
    %{
      "email_address" => user.email,
      "status" => mailchimp_status(user.newsletter),
      "merge_fields" => %{
        "FNAME" => user.first_name,
        "LNAME" => user.last_name
      }
    }
  end

  defp mailchimp_user_url(%User{email: email}, config) do
    base_url = Keyword.get(config, :base_url)
    newsletter_id = Keyword.get(config, :newsletter_id)
    subscriber_hash = subscriber_hash(email)

    Path.join([base_url, "3.0/lists", newsletter_id, "members", subscriber_hash])
  end

  defp mailchimp_status(true), do: "subscribed"
  defp mailchimp_status(false), do: "unsubscribed"

  defp subscriber_hash(email) do
    :md5
    |> :crypto.hash(String.downcase(email))
    |> Base.encode16(case: :lower)
  end
end

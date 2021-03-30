defmodule Recognizer.Hal do
  @moduledoc """
  A simple API client for the Hal API
  """

  def update_newsletter(user) do
    req = "/accounts/newsletter/interests" |> build_url() |> HTTPoison.get!()
    interests = Jason.decode!(req.body)["interests"]

    groups =
      Enum.reduce(interests, %{}, fn item, acc ->
        Map.put(acc, item["id"], String.to_existing_atom(user["newsletter"]))
      end)

    body =
      %{
        "email_address" => user["email"],
        "status" => mailchimp_status(user["newsletter"]),
        "interests" => groups,
        "merge_fields" => %{
          "FNAME" => user["first_name"],
          "LNAME" => user["last_name"]
        }
      }
      |> Jason.encode!()

    "/accounts/newsletter" |> build_url() |> HTTPoison.post!(body, %{"Content-type" => "application/json"})
  end

  defp build_url(path) do
    base_url = Application.get_env(:recognizer, :hal_url)
    Path.join([base_url, path])
  end

  defp mailchimp_status("true"), do: "subscribed"
  defp mailchimp_status("false"), do: "unsubscribed"
end

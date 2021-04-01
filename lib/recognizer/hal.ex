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

    req = "/accounts/newsletter?email_address=#{user["email"]}" |> build_url() |> HTTPoison.get!()
    status = Jason.decode!(req.body)["status"]

    # only update if not already pending, or subscribed
    # note: this means you cannot unsubscribe from recognizer settings
    unless Enum.member?(["pending", "subscribed"], status) do
      body =
        %{
          "email_address" => user["email"],
          "status" => "pending",
          "interests" => groups,
          "merge_fields" => %{
            "FNAME" => user["first_name"],
            "LNAME" => user["last_name"]
          }
        }
        |> Jason.encode!()

      "/accounts/newsletter" |> build_url() |> HTTPoison.post!(body, %{"Content-type" => "application/json"})
    end
  end

  defp build_url(path) do
    base_url = Application.get_env(:recognizer, :hal_url)
    Path.join([base_url, path])
  end
end

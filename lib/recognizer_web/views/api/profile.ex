defmodule RecognizerWeb.Api.ProfileView do
  use RecognizerWeb, :view

  def render("show.json", %{user: user}) do
    %{
      id: user.id,

      first_name: user.first_name,
      last_name: user.last_name,

      email: user.email,
      phone_number: user.phone_number,

      type: user.type,
      company_name: user.company_name,

      newsletter: user.newsletter,

      notification_preferences: render("notification_preferences.json", user)
    }
  end

  def render("notification_preferences.json", %{notification_preference: preferences}) do
    preferences
    |> Map.take([:two_factor])
  end
end

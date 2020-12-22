defmodule RecognizerWeb.Api.ProfileView do
  use RecognizerWeb, :view

  alias Recognizer.Accounts.Role

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
      admin: Role.admin?(user),
      notification_preferences: render("notification_preferences.json", user)
    }
  end

  def render("notification_preferences.json", %{notification_preference: preferences}) do
    Map.take(preferences, [:two_factor])
  end
end

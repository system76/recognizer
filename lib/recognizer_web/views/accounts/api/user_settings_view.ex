defmodule RecognizerWeb.Accounts.Api.UserSettingsView do
  use RecognizerWeb, :view

  alias Recognizer.Accounts.Role

  def render("show.json", %{user: user}) do
    %{
      user: %{
        id: user.id,
        company_name: user.company_name,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        newsletter: user.newsletter,
        notification_preferences: render("notification_preferences.json", user),
        phone_number: user.phone_number,
        staff: Role.admin?(user),
        two_factor_enabled: user.two_factor_enabled,
        type: user.type,
        third_party_login: user.third_party_login,
        stripe_id: user.stripe_id
      }
    }
  end

  def render("notification_preferences.json", %{notification_preference: preferences}) do
    Map.take(preferences, [:two_factor])
  end

  def render("session.json", %{user: user, access_token: access_token}) do
    "show.json"
    |> render(%{user: user})
    |> Map.put(:session, %{
      token: access_token
    })
  end
end

defmodule RecognizerWeb.Accounts.Api.UserRegistrationView do
  use RecognizerWeb, :view

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
end

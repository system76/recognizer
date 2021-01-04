defmodule RecognizerWeb.Accounts.Api.UserSettingsView do
  use RecognizerWeb, :view

  alias Recognizer.Accounts.Role
  alias RecognizerWeb.Authentication

  def render("confirm_two_factor.json", %{settings: %{notification_preferences: %{two_factor: "app"}}, user: user}) do
    %{
      two_factor: %{
        barcode: Authentication.generate_totp_barcode(user),
        method: "app",
        recovery_codes: Map.get(settings, :recovery_codes),
        totp_app_url: Authentication.get_totp_app_url(user)
      }
    }
  end

  def render("confirm_two_factor.json", %{settings: %{notification_preferences: preference, recovery_codes: codes}}) do
    %{
      two_factor: %{
        method: preference,
        recovery_codes: codes
      }
    }
  end

  def render("session.json", %{user: user, access_token: access_token}) do
    "show.json"
    |> render(%{user: user})
    |> Map.put(:session, %{
      token: access_token
    })
  end

  def render("show.json", %{user: user}) do
    %{
      user: %{
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone_number: user.phone_number,
        type: user.type,
        company_name: user.company_name,
        newsletter: user.newsletter,
        staff: Role.admin?(user),
        two_factor_enabled: user.two_factor_enabled,
        notification_preferences: render("notification_preferences.json", user)
      }
    }
  end

  def render("notification_preferences.json", %{notification_preference: preferences}) do
    Map.take(preferences, [:two_factor])
  end
end

defmodule RecognizerWeb.Accounts.Api.UserSettingsView do
  use RecognizerWeb, :view

  alias Recognizer.Accounts.Role

  def render("confirm_authenticator.json", %{barcode: barcode, totp_app_url: totp_app_url}) do
    %{
      two_factor: %{
        barcode: barcode,
        totp_app_url: totp_app_url
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
        two_factor_seed: user.two_factor_seed,
        notification_preferences: render("notification_preferences.json", user)
      }
    }
  end

  def render("notification_preferences.json", %{notification_preference: preferences}) do
    Map.take(preferences, [:two_factor])
  end
end

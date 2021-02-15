defmodule RecognizerWeb.Accounts.Api.UserSettingsTwoFactorView do
  use RecognizerWeb, :view

  alias RecognizerWeb.Authentication

  def render("show.json", %{user: user} = params) do
    two_factor =
      if params |> Map.get(:settings, nil) |> is_nil() do
        %{two_factor: nil}
      else
        %{
          two_factor: %{
            barcode: Authentication.generate_totp_barcode(user, params.settings),
            method: params.settings.notification_preference.two_factor,
            recovery_codes: recovery_codes(params.settings),
            totp_app_url: Authentication.get_totp_app_url(user, params.settings)
          }
        }
      end

    user
    |> render_one(RecognizerWeb.Accounts.Api.UserSettingsView, "show.json", as: :user)
    |> Map.merge(two_factor)
  end

  defp recovery_codes(%{recovery_codes: recovery_codes}), do: Enum.map(recovery_codes, &Map.get(&1, :code))
end

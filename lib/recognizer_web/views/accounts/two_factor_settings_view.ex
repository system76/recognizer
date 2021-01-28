defmodule RecognizerWeb.Accounts.TwoFactorSettingsView do
  use RecognizerWeb, :view

  alias RecognizerWeb.Authentication

  def has_phone_number?(%{phone_number: nil}), do: false
  def has_phone_number?(%{phone_number: ""}), do: false
  def has_phone_number?(%{phone_number: _phone_number}), do: true

  def two_factor_barcode(user, settings) do
    Authentication.generate_totp_barcode(user, settings["two_factor_seed"])
  end

  def two_factor_url(user, settings) do
    Authentication.get_totp_app_url(user, settings["two_factor_seed"])
  end
end

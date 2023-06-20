defmodule RecognizerWeb.Accounts.UserSettingsView do
  use RecognizerWeb, :view

  def business_type_class(changeset) do
    case Ecto.Changeset.get_field(changeset, :type) do
      :individual -> "hidden"
      :business -> ""
    end
  end

  def two_factor_enabled?(changeset) do
    Ecto.Changeset.get_field(changeset, :two_factor_enabled)
  end

  def two_factor_method(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:notification_preference)
    |> Map.get(:two_factor)
  end
end

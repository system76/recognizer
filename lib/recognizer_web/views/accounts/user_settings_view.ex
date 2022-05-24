defmodule RecognizerWeb.Accounts.UserSettingsView do
  use RecognizerWeb, :view

  alias Ecto.Changeset

  def business_type_class(changeset) do
    case Changeset.get_field(changeset, :type) do
      :individual -> "none"
      :business -> "block"
    end
  end

  def two_factor_enabled?(changeset) do
    Changeset.get_field(changeset, :two_factor_enabled)
  end

  def two_factor_method(changeset) do
    changeset
    |> Changeset.get_field(:notification_preference)
    |> Map.get(:two_factor)
  end
end

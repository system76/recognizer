defmodule RecognizerWeb.Accounts.UserRegistrationView do
  use RecognizerWeb, :view

  def business_type_class(changeset) do
    case Ecto.Changeset.get_field(changeset, :type) do
      :individual -> "hidden"
      :business -> ""
    end
  end
end

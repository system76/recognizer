defmodule RecognizerWeb.Accounts.UserRegistrationView do
  use RecognizerWeb, :view

  def account_type(changeset) do
    case Ecto.Changeset.get_field(changeset, :type) do
      :individual -> "individual"
      :business -> "business"
    end
  end

  def business_type_class(changeset) do
    case Ecto.Changeset.get_field(changeset, :type) do
      :individual -> "none"
      :business -> "block"
    end
  end
end

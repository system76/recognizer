defmodule RecognizerWeb.AccountView do
  use RecognizerWeb, :view

  def render("show.json", %{user: user}) do
    Map.take(user, [
      :avatar_filename,
      :company_name,
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :type,
      :username
    ])
  end
end

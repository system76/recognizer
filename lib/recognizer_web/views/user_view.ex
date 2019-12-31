defmodule RecognizerWeb.UserView do
  use RecognizerWeb, :view

  def render("me.json", %{user: user}) do
    Map.take(user, [
      :avatar_filename,
      :company_name,
      :email,
      :first_name,
      :last_name,
      :type,
      :username
    ])
  end
end

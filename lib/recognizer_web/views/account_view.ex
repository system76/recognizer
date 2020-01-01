defmodule RecognizerWeb.AccountView do
  use RecognizerWeb, :view

  def render("show.json", %{user: user}) do
    data =
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

    %{data: data}
  end
end

defmodule RecognizerWeb.AuthView do
  use RecognizerWeb, :view

  def render("tokens.json", %{access_token: access, refresh_token: refresh}) do
    data = %{
      access_token: access,
      refresh_token: refresh
    }

    %{data: data}
  end
end

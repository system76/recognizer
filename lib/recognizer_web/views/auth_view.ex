defmodule RecognizerWeb.AuthView do
  use RecognizerWeb, :view

  def render("tokens.json", %{access_token: access, refresh_token: refresh}) do
    %{
      data: %{
        attributes: %{
          access_token: access,
          refresh_token: refresh
        },
        id: access,
        type: "auth"
      }
    }
  end
end

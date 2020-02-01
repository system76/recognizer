defmodule RecognizerWeb.AuthViewTest do
  use RecognizerWeb.ConnCase, async: true

  import Phoenix.View

  test "renders me.json" do
    access_token = "access"
    refresh_token = "refresh"

    assert %{
             data: %{
               attributes: %{
                 access_token: ^access_token,
                 refresh_token: ^refresh_token
               },
               id: ^access_token,
               type: "auth"
             }
           } =
             render(RecognizerWeb.AuthView, "tokens.json",
               access_token: access_token,
               refresh_token: refresh_token
             )
  end
end

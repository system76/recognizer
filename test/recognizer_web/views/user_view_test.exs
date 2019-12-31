defmodule RecognizerWeb.UserViewTest do
  use RecognizerWeb.ConnCase, async: true

  import Phoenix.View
  import Recognizer.Factories

  test "renders me.json" do
    %{
      email: email,
      first_name: first_name,
      last_name: last_name,
      type: type,
      username: username
    } = user = build(:user)

    assert %{
             email: ^email,
             first_name: ^first_name,
             last_name: ^last_name,
             type: ^type,
             username: ^username
           } = render(RecognizerWeb.UserView, "me.json", user: user)
  end
end

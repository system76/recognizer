defmodule RecognizerWeb.AccountViewTest do
  use RecognizerWeb.ConnCase, async: true

  import Phoenix.View
  import Recognizer.Factories

  test "renders show.json" do
    %{
      email: email,
      first_name: first_name,
      last_name: last_name,
      id: user_id,
      type: type,
      username: username
    } = user = build(:user)

    assert %{
             data: %{
               attributes: %{
                 email: ^email,
                 first_name: ^first_name,
                 last_name: ^last_name,
                 type: ^type,
                 username: ^username
               },
               id: ^user_id,
               type: "user"
             }
           } = render(RecognizerWeb.AccountView, "show.json", user: user)
  end
end

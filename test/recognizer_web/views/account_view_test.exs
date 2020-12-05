defmodule RecognizerWeb.AccountViewTest do
  use RecognizerWeb.ConnCase, async: true

  import Phoenix.View
  import Recognizer.Factories

  test "renders show.json" do
    user = build(:user)

    assert %{
             avatar_filename: user.avatar_filename,
             company_name: user.company_name,
             email: user.email,
             first_name: user.first_name,
             last_name: user.last_name,
             phone_number: user.phone_number,
             type: user.type,
             username: user.username
           } == render(RecognizerWeb.AccountView, "show.json", user: user)
  end
end

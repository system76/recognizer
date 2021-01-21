defmodule RecognizerWeb.Accounts.Prompt.TwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountsFixtures

  setup %{conn: conn} do
    user =
      :user
      |> build()
      |> add_organization_policy(two_factor_required: true)
      |> insert()

    %{
      conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          prompt_user_id: user.id
        }),
      user: user
    }
  end

  describe "GET /prompt/setup-two-factor" do
    test "renders the two factor page", %{conn: conn} do
      conn = get(conn, Routes.prompt_two_factor_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Two Factor</h2>"
    end
  end

  describe "POST /prompt/setup-two-factor" do
    test "updates the user notification settings", %{conn: conn} do
      new_conn =
        post(conn, Routes.prompt_two_factor_path(conn, :create), %{
          "user" => %{
            "notification_preference" => %{
              "two_factor" => "app"
            }
          }
        })

      assert redirected_to(new_conn) == "/prompt/setup-two-factor/confirm"
    end
  end
end

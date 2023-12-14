defmodule RecognizerWeb.Accounts.Prompt.TwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Mox
  import Recognizer.AccountFactory
  import Recognizer.BigCommerceTestHelpers

  setup :verify_on_exit!

  setup %{conn: conn} do
    user =
      :user
      |> build()
      |> add_organization_policy(two_factor_app_required: true)
      |> insert()

    %{
      conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          prompt_user_id: user.id
        }),
      empty_conn: conn,
      user: user
    }
  end

  describe "GET /prompt/setup-two-factor" do
    test "renders the two factor page", %{conn: conn} do
      conn = get(conn, Routes.prompt_two_factor_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Two Factor</h2>"
    end

    test "renders unauthenticated error if not logged in", %{empty_conn: conn} do
      conn = get(conn, Routes.prompt_two_factor_path(conn, :new))
      assert redirected_to(conn) == "/login"
    end
  end

  describe "PUT /prompt/setup-two-factor" do
    test "updates the user notification settings", %{conn: conn} do
      expect(HTTPoisonMock, :put, 1, fn _, _, _ -> ok_bigcommerce_response() end)

      new_conn =
        put(conn, Routes.prompt_two_factor_path(conn, :create), %{
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

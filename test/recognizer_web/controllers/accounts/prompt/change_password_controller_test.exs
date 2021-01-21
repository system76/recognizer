defmodule RecognizerWeb.Accounts.Prompt.ChangePasswordControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountsFixtures

  alias Recognizer.Accounts

  setup %{conn: conn} do
    user =
      :user
      |> build(inserted_at: NaiveDateTime.add(NaiveDateTime.utc_now(), -999_999, :second))
      |> add_organization_policy(password_expiration: 1)
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

  describe "GET /prompt/update-password" do
    test "renders the change password page", %{conn: conn} do
      conn = get(conn, Routes.prompt_password_change_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Update Password</h2>"
    end

    test "renders unauthenticated error if not logged in", %{empty_conn: conn} do
      conn = get(conn, Routes.prompt_password_change_path(conn, :edit))
      assert redirected_to(conn) == "/login"
    end
  end

  describe "PUT /prompt/update-password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.prompt_password_change_path(conn, :update), %{
          "current_password" => user.password,
          "user" => %{
            "password" => "NeWVa3!pa33wor@d",
            "password_confirmation" => "NeWVa3!pa33wor@d"
          }
        })

      assert Accounts.get_user_by_email_and_password(user.email, "NeWVa3!pa33wor@d")
      assert redirected_to(new_password_conn) == "/settings"
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.prompt_password_change_path(conn, :update), %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Update Password</h2>"
      assert response =~ "must contain a number"
      assert response =~ "does not match password"
      assert response =~ "is not valid"
    end
  end
end

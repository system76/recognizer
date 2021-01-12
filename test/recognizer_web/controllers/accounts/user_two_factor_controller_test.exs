defmodule RecognizerWeb.Accounts.UserTwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountsFixtures

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  setup %{conn: conn} do
    user = user_fixture()
    seed = Recognizer.Accounts.generate_new_two_factor_seed()

    updated_user =
      user
      |> Recognizer.Repo.preload([:notification_preference, :recovery_codes])
      |> Accounts.User.two_factor_changeset(%{
        notification_preference: %{two_factor: "text"},
        recovery_codes: Recognizer.Accounts.generate_new_recovery_codes(user),
        two_factor_enabled: true,
        two_factor_seed: seed
      })
      |> Recognizer.Repo.update!()

    %{
      conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          current_user_id: user.id
        }),
      user: updated_user
    }
  end

  describe "GET /two_factor" do
    test "renders the two factor input page", %{conn: conn} do
      conn = get(conn, Routes.user_two_factor_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Security Code</h2>"
    end
  end

  describe "POST /two_factor" do
    test "redirects to user settings for successful security codes", %{conn: conn, user: user} do
      token = Authentication.generate_token(user)
      conn = post(conn, Routes.user_two_factor_path(conn, :create), %{"user" => %{"two_factor_code" => token}})
      assert redirected_to(conn) == "/settings"
    end

    test "emits error message with invalid security code", %{conn: conn} do
      conn =
        post(conn, Routes.user_two_factor_path(conn, :create), %{
          "user" => %{"two_factor_code" => "INVALID"}
        })

      assert redirected_to(conn) == "/two_factor"
      assert get_flash(conn, :error) =~ "Invalid"
    end
  end

  describe "POST /two_factor/resend" do
    test "redirects with flash message", %{conn: conn} do
      conn = post(conn, Routes.user_two_factor_path(conn, :resend))

      assert redirected_to(conn) == "/two_factor"
      assert get_flash(conn, :info) =~ "resent"
    end

    test "redirects to user settings for successful recovery code", %{conn: conn, user: user} do
      %{recovery_codes: [%{code: recovery_code} | tail]} = user

      conn = post(conn, Routes.user_two_factor_path(conn, :create), %{"user" => %{"recovery_code" => recovery_code}})
      assert redirected_to(conn) == "/settings"

      %{recovery_codes: remaining_codes} = Recognizer.Repo.preload(user, :recovery_codes, force: true)
      assert length(remaining_codes) == length(tail)
    end
  end
end

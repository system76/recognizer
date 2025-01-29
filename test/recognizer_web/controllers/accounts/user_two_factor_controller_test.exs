defmodule RecognizerWeb.Accounts.UserTwoFactorControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  setup %{conn: conn} do
    user = :user |> build() |> add_two_factor() |> insert()

    %{
      conn:
        Phoenix.ConnTest.init_test_session(conn, %{
          two_factor_user_id: user.id
        }),
      user: user
    }
  end

  defp new_user_conn() do
    conn = Phoenix.ConnTest.build_conn()
    user = :user |> build() |> add_two_factor() |> insert()

    Phoenix.ConnTest.init_test_session(conn, %{
      two_factor_user_id: user.id
    })
  end

  describe "GET /two-factor" do
    test "renders the two factor input page", %{conn: conn} do
      conn = get(conn, Routes.user_two_factor_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Security Code</h2>"
    end
  end

  describe "POST /two-factor" do
    test "redirects to user settings for successful security codes", %{conn: conn, user: user} do
      current_time = System.system_time(:second)
      conn = put_session(conn, :two_factor_issue_time, current_time)
      conn = put_session(conn, :two_factor_user_id, user.id)
      %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(user)

      token = Authentication.generate_token(two_factor_method, current_time, user)
      conn = post(conn, Routes.user_two_factor_path(conn, :create), %{"user" => %{"two_factor_code" => token}})
      assert redirected_to(conn) == "/settings"
    end

    test "emits error message with invalid security code", %{conn: conn} do
      conn = put_session(conn, :two_factor_issue_time, System.system_time(:second) - 60)

      conn =
        post(conn, Routes.user_two_factor_path(conn, :create), %{
          "user" => %{"two_factor_code" => "INVALID"}
        })

      assert redirected_to(conn) == "/two-factor"
      assert Flash.get(conn.assigns.flash, :error) =~ "Invalid"
    end
  end

  describe "GET /two-factor/resend" do
    test "redirects with flash message", %{conn: conn} do
      conn = get(conn, Routes.user_two_factor_path(conn, :resend))

      assert redirected_to(conn) == "/two-factor"
      assert Flash.get(conn.assigns.flash, :info) =~ "Two factor code has been reset"
    end

    test "rate limited", %{conn: conn} do
      Enum.each(0..20, fn _ -> get(conn, Routes.user_two_factor_path(conn, :resend)) end)
      conn = get(conn, Routes.user_two_factor_path(conn, :resend))

      assert response(conn, 429)
    end

    test "rate limited only by user id", %{conn: conn} do
      Enum.each(0..20, fn _ ->
        c = new_user_conn()
        get(c, Routes.user_two_factor_path(c, :resend))
      end)

      conn = get(conn, Routes.user_two_factor_path(conn, :resend))

      assert redirected_to(conn) == "/two-factor"
      assert Flash.get(conn.assigns.flash, :info) =~ "Two factor code has been reset"
    end
  end

  describe "POST /users/two-factor Email (confirm)" do
    test "confirm take timeout genereated token with expire_time", %{conn: conn, user: user} do
      settings = Accounts.generate_and_cache_new_two_factor_settings(user, :email)

      expired_time = System.system_time(:second) - 901
      conn = put_session(conn, :two_factor_issue_time, expired_time)
      conn = put_session(conn, :two_factor_sent, true)

      token = Authentication.generate_token(:email, expired_time, settings)
      params = %{"user" => %{"two_factor_code" => token}}

      conn = post(conn, Routes.user_two_factor_path(conn, :create), params)

      assert redirected_to(conn) =~ "/two-factor"
      assert Flash.get(conn.assigns.flash, :error) =~ "Two factor code is expired"
    end

    test "confirm saves and clears cache", %{conn: conn, user: user} do
      %{notification_preference: %{two_factor: two_factor_method}} = Accounts.load_notification_preferences(user)

      current_time = System.system_time(:second)
      conn = put_session(conn, :two_factor_issue_time, current_time)
      conn = put_session(conn, :two_factor_sent, true)

      token = Authentication.generate_token(two_factor_method, current_time, user)
      params = %{"user" => %{"two_factor_code" => token}}

      conn = post(conn, Routes.user_two_factor_path(conn, :create), params)
      assert redirected_to(conn) =~ "/settings"
    end

    test "confirm redirects without cached settings", %{conn: conn, user: user} do
      current_time = System.system_time(:second)
      conn = put_session(conn, :two_factor_issue_time, current_time)
      conn = put_session(conn, :two_factor_sent, true)

      settings = Accounts.generate_and_cache_new_two_factor_settings(user, :email)
      token = Authentication.generate_token(:app, 0, settings)
      Accounts.clear_two_factor_settings(user)
      params = %{"user" => %{"two_factor_code" => token}}
      conn = post(conn, Routes.user_two_factor_path(conn, :create), params)
      assert redirected_to(conn) =~ "/two-factor"
      assert Flash.get(conn.assigns.flash, :error) =~ "Invalid security code"
    end
  end
end

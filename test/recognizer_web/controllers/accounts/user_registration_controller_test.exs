defmodule RecognizerWeb.Accounts.UserRegistrationControllerTest do
  use RecognizerWeb.ConnCase

  import Mox
  import Recognizer.AccountFactory
  import Recognizer.BigCommerceTestHelpers

  alias Recognizer.Accounts.BCCustomerUser
  alias Recognizer.Accounts.User
  alias Recognizer.Repo

  setup :verify_on_exit!

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Create Account</h2>"
      assert response =~ "Log in</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(insert(:user)) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/settings"
    end

    test "redirects to bigcommerce if already logged in", %{conn: conn} do
      %{user: user} = insert(:bc_customer_user)
      conn = conn |> log_in_user(user) |> get(Routes.user_registration_path(conn, :new, %{"bc" => "true"}))

      assert redirected_to(conn) =~ "http://localhost/login/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and prompts for verification", %{conn: conn} do
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> ok_bigcommerce_response() end)

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      refute Recognizer.Guardian.Plug.current_resource(conn)
      assert redirected_to(conn) =~ "/prompt/verification"
      assert Repo.get_by(BCCustomerUser, bc_id: 1001)
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short", "first_name" => "<>"}
        })

      response = html_response(conn, 200)
      assert response =~ "Create Account</h2>"
      assert response =~ "must have the @ sign, no spaces and a top level domain"
      assert response =~ "must contain a number"
      assert response =~ "must not contain special characters"
    end

    @tag :capture_log
    test "renders an error page for a bigcommerce failure", %{conn: conn} do
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> bad_bigcommerce_response() end)

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      assert Repo.all(User) == []
      refute Recognizer.Guardian.Plug.current_resource(conn)
      response = html_response(conn, 500)
      assert response =~ "Something has gone horribly wrong"
    end

    test "rate limits account creation", %{conn: conn} do
      stub(HTTPoisonMock, :post, fn _, _, _ -> ok_bigcommerce_response() end)

      Enum.each(0..20, fn _ ->
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })
      end)

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      refute Recognizer.Guardian.Plug.current_resource(conn)
      assert response(conn, 429)
    end
  end
end

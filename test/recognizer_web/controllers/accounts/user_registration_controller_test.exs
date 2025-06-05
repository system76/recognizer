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

      redirect =
        conn
        |> log_in_user(user)
        |> get(Routes.user_registration_path(conn, :new, %{"bc" => "true"}))
        |> redirected_to()

      jwt_payload =
        redirect
        |> then(&Regex.named_captures(~r/\.(?<payload>.+)\./, &1))
        |> then(fn %{"payload" => base64} -> base64 end)
        |> Base.decode64!(padding: false)
        |> Jason.decode!(keys: :atoms)

      assert redirect =~ "http://localhost/login/"
      assert %{redirect_to: "/"} = jwt_payload
    end

    test "redirects to bigcommerce checkout if already logged in", %{conn: conn} do
      %{user: user} = insert(:bc_customer_user)

      redirect =
        conn
        |> log_in_user(user)
        |> get(Routes.user_registration_path(conn, :new, %{"bc" => "true", "checkout" => "true"}))
        |> redirected_to()

      jwt_payload =
        redirect
        |> then(&Regex.named_captures(~r/\.(?<payload>.+)\./, &1))
        |> then(fn %{"payload" => base64} -> base64 end)
        |> Base.decode64!(padding: false)
        |> Jason.decode!(keys: :atoms)

      assert redirect =~ "http://localhost/login/"
      assert %{redirect_to: "/checkout"} = jwt_payload
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and prompts for verification", %{conn: conn} do
      expect(HTTPoisonMock, :get, 1, fn _, _, _ -> empty_bigcommerce_response() end)
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> ok_bigcommerce_response() end)

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      refute Recognizer.Guardian.Plug.current_resource(conn)
      assert redirected_to(conn) =~ "/prompt/verification"
      assert Repo.get_by(BCCustomerUser, bc_id: 1001)
    end

    test "creates account linked to existing bigcommerce account", %{conn: conn} do
      expect(HTTPoisonMock, :get, 1, fn _, _, _ -> ok_bigcommerce_response() end)

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
    test "handles bigcommerce failure gracefully and continues account creation", %{conn: conn} do
      expect(HTTPoisonMock, :get, 1, fn _, _, _ -> empty_bigcommerce_response() end)
      expect(HTTPoisonMock, :post, 1, fn _, _, _ -> bad_bigcommerce_response() end)

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => params_for(:user)
        })

      # User is created even though BigCommerce fails
      assert [%User{}] = Repo.all(User)
      refute Recognizer.Guardian.Plug.current_resource(conn)
      # User is redirected to verification page
      assert redirected_to(conn) =~ "/prompt/verification"
      # But no BigCommerce user is created
      refute Repo.get_by(BCCustomerUser, user_id: Repo.one(User).id)
    end

    test "rate limits account creation", %{conn: conn} do
      stub(HTTPoisonMock, :get, fn _, _, _ -> empty_bigcommerce_response() end)
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

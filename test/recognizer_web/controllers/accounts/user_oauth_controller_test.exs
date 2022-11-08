defmodule RecognizerWeb.Accounts.UserOauthControllerTest do
  use RecognizerWeb.ConnCase

  import Recognizer.AccountFactory

  alias RecognizerWeb.Accounts.UserOAuthController

  @moduletag capture_log: true

  defp ueberauth_fixture(%{service: service, service_guid: guid}, attrs \\ %{}) do
    %Ueberauth.Auth{
      provider: service,
      uid: guid,
      info:
        Map.merge(
          %{
            name: "John Doe",
            email: build(:email)
          },
          attrs
        )
    }
  end

  describe "callback/2" do
    test "logs in a user with third part service", %{conn: conn} do
      user = insert(:user)
      auth = :oauth |> insert() |> ueberauth_fixture(%{email: user.email})

      conn =
        conn
        |> bypass_through(RecognizerWeb.Router, [:browser])
        |> get(Routes.user_oauth_path(conn, :callback, "github"))
        |> assign(:ueberauth_auth, auth)
        |> UserOAuthController.callback(%{})

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
    end

    test "sends two factor enabled account to two factor screen", %{conn: conn} do
      user = :user |> build() |> add_two_factor() |> insert()
      auth = :oauth |> insert() |> ueberauth_fixture(%{email: user.email})

      conn =
        conn
        |> bypass_through(RecognizerWeb.Router, [:browser])
        |> get(Routes.user_oauth_path(conn, :callback, "github"))
        |> assign(:ueberauth_auth, auth)
        |> UserOAuthController.callback(%{})

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
    end

    test "creates a new user with third party service information", %{conn: conn} do
      auth = :oauth |> insert() |> ueberauth_fixture()

      conn =
        conn
        |> bypass_through(RecognizerWeb.Router, [:browser])
        |> get(Routes.user_oauth_path(conn, :callback, "github"))
        |> assign(:ueberauth_auth, auth)
        |> UserOAuthController.callback(%{})

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
    end

    test "gives a friendly error to users with email already created", %{conn: conn} do
      user = insert(:user)
      auth = ueberauth_fixture(%{service: :github, service_guid: 1}, %{email: user.email})

      conn =
        conn
        |> bypass_through(RecognizerWeb.Router, [:browser])
        |> get(Routes.user_oauth_path(conn, :callback, "github"))
        |> assign(:ueberauth_auth, auth)
        |> UserOAuthController.callback(%{})

      assert get_flash(conn, :error) ==
               "An error occurred. This may indicate you have previously created an account using the email and password combination."
    end

    test "gives changeset validation error on other creating user errors", %{conn: conn} do
      auth = ueberauth_fixture(%{service: :github, service_guid: 1}, %{email: "test"})

      conn =
        conn
        |> bypass_through(RecognizerWeb.Router, [:browser])
        |> get(Routes.user_oauth_path(conn, :callback, "github"))
        |> assign(:ueberauth_auth, auth)
        |> UserOAuthController.callback(%{})

      assert get_flash(conn, :error) == "An error occurred. Please contact support."
    end
  end
end

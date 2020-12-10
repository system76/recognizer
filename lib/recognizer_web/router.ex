defmodule RecognizerWeb.Router do
  use RecognizerWeb, :router

  import RecognizerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RecognizerWeb do
    pipe_through :browser

    get "/", HomepageController, :index
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/create-account", UserRegistrationController, :new
    post "/create-account", UserRegistrationController, :create
    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create
    get "/forgot-password", UserResetPasswordController, :new
    post "/forgot-password", UserResetPasswordController, :create
    get "/forgot-password/:token", UserResetPasswordController, :edit
    put "/forgot-password/:token", UserResetPasswordController, :update

    get "/oauth/:provider", OAuthController, :request
    get "/oauth/:provider/callback", OAuthController, :callback
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :require_authenticated_user]

    get "/settings", UserSettingsController, :edit
    put "/settings", UserSettingsController, :update
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser]

    delete "/logout", UserSessionController, :delete
  end

  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:browser, :require_authenticated_user]

    get "/oauth/authorize", AuthorizeController, :new
    get "/oauth/authorize/:code", AuthorizeController, :show
    post "/oauth/authorize", AuthorizeController, :create
    delete "/oauth/authorize", AuthorizeController, :delete
  end
end

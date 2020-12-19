defmodule RecognizerWeb.Router do
  use RecognizerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug RecognizerWeb.AuthPlug
  end

  pipeline :user do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :guest do
    plug Guardian.Plug.EnsureNotAuthenticated
  end

  scope "/", RecognizerWeb do
    pipe_through :browser

    get "/", HomepageController, :index

    delete "/logout", Accounts.UserSessionController, :delete
  end

  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:api]

    post "/oauth/token", TokenController, :create
  end

  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:browser, :auth, :user]

    get "/oauth/authorize", AuthorizeController, :new
    get "/oauth/authorize/:code", AuthorizeController, :show
    post "/oauth/authorize", AuthorizeController, :create
    delete "/oauth/authorize", AuthorizeController, :delete
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :auth, :guest]

    get "/create-account", UserRegistrationController, :new
    post "/create-account", UserRegistrationController, :create
    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create
    get "/forgot-password", UserResetPasswordController, :new
    post "/forgot-password", UserResetPasswordController, :create
    get "/forgot-password/:token", UserResetPasswordController, :edit
    put "/forgot-password/:token", UserResetPasswordController, :update

    get "/oauth/:provider", UserOAuthController, :request, as: :user_oauth
    get "/oauth/:provider/callback", UserOAuthController, :callback, as: :user_oauth

    get "/two_factor", UserTwoFactorController, :new
    post "/two_factor", UserTwoFactorController, :create
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :auth, :user]

    get "/settings", UserSettingsController, :edit
    put "/settings", UserSettingsController, :update
    post "/confirm_authenicator", UserSettingsController, :confirm_authenticator
  end
end

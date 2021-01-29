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

    get "/logout", Accounts.UserSessionController, :delete
  end

  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:api]

    post "/oauth/token", TokenController, :create
  end

  scope "/api", RecognizerWeb.Accounts.Api, as: :api do
    pipe_through [:api, :auth, :user]

    get "/settings", UserSettingsController, :show
    put "/settings", UserSettingsController, :update

    get "/settings/two-factor", UserSettingsTwoFactorController, :show
    put "/settings/two-factor", UserSettingsTwoFactorController, :update
    post "/settings/two-factor/send", UserSettingsTwoFactorController, :send
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

    get "/two-factor", UserTwoFactorController, :new
    post "/two-factor", UserTwoFactorController, :create
    post "/two-factor/resend", UserTwoFactorController, :resend

    get "/recovery-code", UserRecoveryCodeController, :new
    post "/recovery-code", UserRecoveryCodeController, :create
  end

  scope "/", RecognizerWeb.Accounts.Prompt, as: :prompt do
    pipe_through [:browser, :auth, :guest]

    get "/prompt/update-password", PasswordChangeController, :edit
    put "/prompt/update-password", PasswordChangeController, :update

    get "/prompt/setup-two-factor", TwoFactorController, :new
    put "/prompt/setup-two-factor", TwoFactorController, :create
    get "/prompt/setup-two-factor/confirm", TwoFactorController, :edit
    post "/prompt/setup-two-factor/confirm", TwoFactorController, :update
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :auth, :user]

    get "/settings", UserSettingsController, :edit
    put "/settings", UserSettingsController, :update
    get "/settings/two-factor", UserSettingsController, :two_factor
    post "/settings/two-factor", UserSettingsController, :two_factor_confirm
  end
end

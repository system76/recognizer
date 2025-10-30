defmodule RecognizerWeb.Router do
  use RecognizerWeb, :router

  @hsts_header %{
    "strict-transport-security" => "max-age=31536000"
  }

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers, @hsts_header
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

  pipeline :bc do
    plug :add_bc_to_session
  end

  defp add_bc_to_session(%{query_params: %{"bc" => "true", "checkout" => "true"}} = conn, _opts) do
    if Recognizer.BigCommerce.enabled?() do
      conn
      |> put_session(:bc_checkout, true)
      |> put_session(:bc, true)
    else
      conn
    end
  end

  defp add_bc_to_session(%{query_params: %{"bc" => "true"}} = conn, _opts) do
    if Recognizer.BigCommerce.enabled?() do
      conn
      |> delete_session(:bc_checkout)
      |> put_session(:bc, true)
    else
      conn
    end
  end

  defp add_bc_to_session(conn, _opts) do
    conn
  end

  scope "/", RecognizerWeb do
    pipe_through [:browser, :bc]

    get "/", HomepageController, :index

    get "/logout", Accounts.UserSessionController, :delete
  end

  # OAuth authorization flow (browser-based) - must come BEFORE catch-all
  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:browser, :bc, :auth, :user]

    get "/oauth/authorize", AuthorizeController, :new
    get "/oauth/authorize/:code", AuthorizeController, :show
    post "/oauth/authorize", AuthorizeController, :create
    delete "/oauth/authorize", AuthorizeController, :delete
  end

  # OAuth token endpoint and catch-all for invalid OAuth paths
  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:api]

    post "/oauth/token", TokenController, :create
    match :*, "/oauth/token", TokenController, :method_not_allowed
    # Catch-all for any other /oauth/* paths (security: prevents endpoint scanning)
    match :*, "/oauth/*path", TokenController, :not_found
  end

  scope "/api", RecognizerWeb.Accounts.Api, as: :api do
    pipe_through [:api, :auth, :user]

    get "/settings", UserSettingsController, :show
    put "/settings", UserSettingsController, :update

    get "/settings/two-factor", UserSettingsTwoFactorController, :show
    put "/settings/two-factor", UserSettingsTwoFactorController, :update
    post "/settings/two-factor/send", UserSettingsTwoFactorController, :send
    post "/create-account", UserRegistrationController, :create
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :bc, :auth, :guest]

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
    get "/two-factor/resend", UserTwoFactorController, :resend

    get "/recovery-code", UserRecoveryCodeController, :new
    post "/recovery-code", UserRecoveryCodeController, :create

    get "/verify/:code", VerificationCodeController, :new
  end

  scope "/", RecognizerWeb.Accounts.Prompt, as: :prompt do
    pipe_through [:browser, :bc, :auth, :guest]

    get "/prompt/update-password", PasswordChangeController, :edit
    put "/prompt/update-password", PasswordChangeController, :update

    get "/prompt/setup-two-factor", TwoFactorController, :new
    put "/prompt/setup-two-factor", TwoFactorController, :create
    get "/prompt/setup-two-factor/confirm", TwoFactorController, :edit
    post "/prompt/setup-two-factor/confirm", TwoFactorController, :update

    get "/prompt/verification", VerificationController, :new
    post "/prompt/verification", VerificationController, :resend
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :bc, :auth, :user]

    get "/settings", UserSettingsController, :edit
    put "/settings", UserSettingsController, :update
    get "/settings/two-factor/review", UserSettingsController, :review
    get "/settings/two-factor", UserSettingsController, :two_factor_init
    post "/settings/two-factor", UserSettingsController, :two_factor_confirm
    get "/setting/two-factor/resend", UserSettingsController, :resend
  end

  # Catch-all route for invalid OAuth endpoints
  # IMPORTANT: This MUST be the last route to avoid blocking legitimate OAuth routes
  # Handles scanning attempts like /oauth/.env, /oauth/auth.json, etc.
  scope "/", RecognizerWeb.OauthProvider, as: :oauth do
    pipe_through [:api]

    match :*, "/oauth/*path", TokenController, :not_found
  end
end

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

  # Other scopes may use custom stacks.
  # scope "/api", RecognizerWeb do
  #   pipe_through :api
  # end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", RecognizerWeb.Accounts do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end
end

defmodule RecognizerWeb.Router do
  use RecognizerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug RecognizerWeb.Plugs.VerifyAudience
  end

  pipeline :auth do
    plug RecognizerWeb.Plugs.AuthenticationPipeline
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", RecognizerWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", RecognizerWeb do
    pipe_through [:api]

    post "/accounts", AccountController, :create

    get "/healthcheck", HealthCheckController, :index
  end

  scope "/", RecognizerWeb do
    pipe_through [:api, :auth]

    get "/me", AccountController, :show
    patch "/me", AccountController, :update
  end

  scope "/auth", RecognizerWeb do
    pipe_through :api

    post "/login", AuthController, :login
    post "/exchange", AuthController, :exchange
  end
end

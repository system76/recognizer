defmodule RecognizerWeb.Router do
  use RecognizerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RecognizerWeb do
    pipe_through :api
  end
end

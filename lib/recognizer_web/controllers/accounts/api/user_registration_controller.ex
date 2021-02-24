defmodule RecognizerWeb.Accounts.Api.UserRegistrationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts.Role
  alias Recognizer.Accounts
  alias RecognizerWeb.FallbackController

  def create(conn, %{"user" => user_params}) do
    with true <- staff_request?(conn),
         {:ok, user} <- Accounts.register_user(user_params, skip_password: true) do
      conn
      |> put_status(201)
      |> put_view(RecognizerWeb.Accounts.Api.UserSettingsView)
      |> render("show.json", user: user)
    end
  end

  def staff_request?(conn) do
    user = Guardian.Plug.current_resource(conn)

    if Role.admin?(user) do
      true
    else
      FallbackController.auth_error(conn, {:invalid_token, "insufficient permissions"}, :ignored)
    end
  end
end

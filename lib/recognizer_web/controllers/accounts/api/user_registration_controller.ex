defmodule RecognizerWeb.Accounts.Api.UserRegistrationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts.Role
  alias Recognizer.{Accounts, Guardian}
  alias RecognizerWeb.ErrorView

  def create(conn, %{"user" => user_params}) do
    with true <- staff_request?(conn),
         {:ok, user} <- Accounts.register_user(user_params, skip_password: true) do
      render(conn, "show.json", user: user)
    end
  end

  def staff_request(conn) do
    user = Guardian.current_resource(conn)

    if Role.admin?(user) do
      true
    else
      {:invalid_token, "insufficient permissions"}
    end
  end
end

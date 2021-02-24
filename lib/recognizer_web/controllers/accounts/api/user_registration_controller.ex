defmodule RecognizerWeb.Accounts.Api.UserRegistrationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.ErrorView

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params, skip_password: true) do
      {:ok, user} ->
        render(conn, "show.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> put_view(ErrorView)
        |> render("error.json", changeset: changeset)
    end
  end
end

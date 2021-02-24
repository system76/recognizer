defmodule RecognizerWeb.Accounts.Api.UserRegistrationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts.Role
  alias Recognizer.{Accounts, Guardian}
  alias RecognizerWeb.ErrorView

  plug :staff_only

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

  def staff_only(conn, _opts) do
    user = Guardian.current_resource(conn)

    if Role.admin?(user) do
      conn
    else
      conn
      |> send_resp(401, "")
      |> halt()
    end
  end
end

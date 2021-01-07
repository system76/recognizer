defmodule RecognizerWeb.Accounts.UserRegistrationController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Accounts.User
  alias RecognizerWeb.Authentication

  def new(conn, params) do
    user_params = Map.get(params, "user", %{})
    changeset = Accounts.change_user_registration(%User{}, user_params)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> Authentication.conditional_flash(:info, "User created successfully.")
        |> Authentication.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end

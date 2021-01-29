defmodule RecognizerWeb.Accounts.Api.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.{Authentication, ErrorView}

  def update(conn, %{"action" => "update", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user(user, user_params) do
      {:ok, updated_user} ->
        render(conn, "show.json", user: updated_user)

      {:error, changeset} ->
        conn
        |> put_view(ErrorView)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, updated_user} ->
        Authentication.revoke_all_tokens(updated_user)
        {:ok, access_token} = Authentication.log_in_api_user(updated_user)

        render(conn, "session.json", user: updated_user, access_token: access_token)

      {:error, changeset} ->
        conn
        |> put_view(ErrorView)
        |> render("error.json", changeset: changeset)
    end
  end

  def show(conn, _params) do
    user = Authentication.fetch_current_user(conn)
    render(conn, "show.json", user: user)
  end
end

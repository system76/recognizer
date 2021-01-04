defmodule RecognizerWeb.Accounts.Api.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias Recognizer.Notifications.Account
  alias RecognizerWeb.{Authentication, ErrorView}

  def confirm_two_factor(conn, params) do
    two_factor_code = Map.get(params, "two_factor_code", "")
    user = Authentication.fetch_current_user(conn)

    case Accounts.confirm_and_save_two_factor_settings(two_factor_code, user) do
      {:ok, updated_user} ->
        render(conn, "show.json", user: updated_user)

      _ ->
        conn
        |> put_view(ErrorView)
        |> render("error.json",
          field: :two_factor_token,
          reason: "Failed to confirm settings."
        )
    end
  end

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

  def update(conn, %{"action" => "update_two_factor", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)
    preference = get_in(user_params, ["notification_preference", "two_factor"])
    settings = Accounts.generate_and_cache_new_two_factor_settings(user, preference)

    conn
    |> put_status(202)
    |> render("confirm_two_factor.json", settings: settings, user: user)
  end

  def show(conn, _params) do
    user = Authentication.fetch_current_user(conn)
    render(conn, "show.json", user: user)
  end
end

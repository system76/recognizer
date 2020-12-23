defmodule RecognizerWeb.Accounts.Api.UserSettingsController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.{Authentication, ErrorView}

  def confirm_authenticator(conn, params) do
    two_factor_code = Map.get(params, "two_factor_code", "")
    user = Authentication.fetch_current_user(conn)

    case Authentication.valid_token?(two_factor_code, user) do
      true ->
        {:ok, _} = Accounts.update_user_two_factor(user, %{"notification_preference" => %{"two_factor" => "app"}})
        render(conn, "show.json", user: user)

      false ->
        render(conn, ErrorView, "error.json",
          field: :two_factor_token,
          reason: "Authenticator app security code is invalid."
        )
    end
  end

  def update(conn, %{"action" => "update", "user" => user_params}) do
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user(user, user_params) do
      {:ok, updated_user} ->
        render(conn, "show.json", user: updated_user)

      {:error, changeset} ->
        render(conn, ErrorView, "error.json", changeset: changeset)
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
        render(conn, ErrorView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{
        "action" => "update_two_factor",
        "user" => %{"notification_preference" => %{"two_factor" => "app"}} = user_params
      }) do
    user = Authentication.fetch_current_user(conn)
    user_params = Map.drop(user_params, ["notification_preference"])

    case Accounts.update_user_two_factor(user, user_params) do
      {:ok, user} ->
        conn
        |> put_status(202)
        |> render("confirm_authenticator.json",
          barcode: Authentication.generate_totp_barcode(user),
          totp_app_url: Authentication.get_totp_app_url(user)
        )

      {:error, changeset} ->
        render(conn, ErrorView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_two_factor"} = params) do
    %{"user" => user_params} = params
    user = Authentication.fetch_current_user(conn)

    case Accounts.update_user_two_factor(user, user_params) do
      {:ok, %{notification_preference: %{two_factor: _}}} ->
        render(conn, "show.json", user: user)

      {:error, changeset} ->
        render(conn, ErrorView, "error.json", changeset: changeset)
    end
  end

  def show(conn, _params) do
    user = Authentication.fetch_current_user(conn)
    render(conn, "show.json", user: user)
  end
end

defmodule RecognizerWeb.Accounts.Api.UserSettingsTwoFactorController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.{Authentication, ErrorView}

  @one_minute 60_000
  @one_hour 3_600_000

  plug Hammer.Plug,
       [
         rate_limit: {"api:two_factor", @one_minute, 3},
         by: {:conn, &get_user_id_from_request/1}
       ]
       when action in [:send]
      #  when action in [:send, :update]

  plug Hammer.Plug,
       [
         rate_limit: {"api:two_factor_hour", @one_hour, 6},
         by: {:conn, &get_user_id_from_request/1}
       ]
       when action in [:send]
      #  when action in [:send, :update]

  def show(conn, _params) do
    user = Authentication.fetch_current_user(conn)

    with {:ok, settings} <- Accounts.get_new_two_factor_settings(user) do
      render(conn, "show.json", settings: settings, user: user)
    end
  end

  def update(conn, %{"enabled" => false}) do
    user = Authentication.fetch_current_user(conn)
    IO.inspect(false, label: "enabled")
    with {:ok, updated_user} <- Accounts.update_user_two_factor(user, %{"two_factor_enabled" => false}) do
      render(conn, "show.json", user: updated_user)
    end
  end

  def update(conn, %{"enabled" => true, "type" => preference}) do
    user = Authentication.fetch_current_user(conn)
    settings = Accounts.generate_and_cache_new_two_factor_settings(user, preference)
    IO.inspect(true, label: "enabled")
    IO.inspect(preference, label: "preference")

    conn
    |> put_status(202)
    |> render("show.json", settings: settings, user: user)
  end

  def update(conn, %{"verification" => code}) do
    user = Authentication.fetch_current_user(conn)
    counter = get_session(conn, :two_factor_issue_time)
    IO.inspect(code, label: "code")
    IO.inspect(counter, label: "update")

    case Accounts.confirm_and_save_two_factor_settings(code, counter, user) do
      {:ok, updated_user} ->
        render(conn, "show.json", user: updated_user)

      _ ->
        conn
        |> put_status(400)
        |> put_view(ErrorView)
        |> render("error.json",
          field: :two_factor_code,
          reason: "Failed to confirm settings."
        )
    end
  end

  def send(conn, _params) do
    user = Authentication.fetch_current_user(conn)

    with {:ok, settings} <- Accounts.get_new_two_factor_settings(user),
         :ok <- Accounts.send_new_two_factor_notification(user, settings) do
      conn
      |> put_status(202)
      |> render("show.json", settings: settings, user: user)
    end
  end
end

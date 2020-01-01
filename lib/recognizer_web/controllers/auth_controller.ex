defmodule RecognizerWeb.AuthController do
  use RecognizerWeb, :controller

  alias Recognizer.Auth
  alias RecognizerWeb.FallbackController

  action_fallback FallbackController

  def exchange(conn, %{"data" => %{"token" => refresh_token}}) do
    audience_id = conn.assigns[:audience_id]

    with {:ok, access, refresh} <- Auth.exchange(refresh_token, audience_id) do
      render_auth_tokens(conn, access, refresh)
    end
  end

  def login(conn, %{"data" => %{"email" => email, "password" => password}}) do
    audience_id = conn.assigns[:audience_id]

    with {:ok, access, refresh} <- Auth.login(email, password, audience_id) do
      render_auth_tokens(conn, access, refresh)
    end
  end

  defp render_auth_tokens(conn, access, refresh) do
    conn
    |> put_status(201)
    |> render("tokens.json", access_token: access, refresh_token: refresh)
  end
end

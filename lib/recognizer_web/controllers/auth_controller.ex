defmodule RecognizerWeb.AuthController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.{ErrorView, FallbackController}
  alias Recognizer.Auth

  @behaviour Guardian.Plug.ErrorHandler

  action_fallback FallbackController

  @impl true
  def auth_error(conn, {:invalid_audience, _reason}, _opts),
    do: render_auth_error(conn, "missing or invalid api token")

  def auth_error(conn, {:invalid_token, _reason}, _opts),
    do: render_auth_error(conn, "missing or invalid access token")

  def auth_error(conn, {:unauthenticated, _reason}, _opts),
    do: render_auth_error(conn, "unauthorized request")

  def auth_error(conn, {:no_resource_found, _reason}, _opts),
    do: render_auth_error(conn, "invalid authenticated resource")

  def exchange(conn, %{"data" => %{"token" => refresh_token}}) do
    audience_id = conn.assigns[:audience_id]

    with {:ok, access, refresh} <- Auth.exchange(refresh_token, audience_id) do
      conn
      |> put_status(201)
      |> render("tokens.json", access_token: access, refresh_token: refresh)
    else
      {:error, reason} -> render_auth_error(conn, reason)
    end
  end

  def login(conn, %{"data" => %{"email" => email, "password" => password}}) do
    audience_id = conn.assigns[:audience_id]

    with {:ok, access, refresh} <- Auth.login(email, password, audience_id) do
      conn
      |> put_status(201)
      |> render("tokens.json", access_token: access, refresh_token: refresh)
    else
      {:error, reason} -> render_auth_error(conn, reason)
    end
  end

  defp render_auth_error(conn, reason) do
    conn
    |> put_view(ErrorView)
    |> put_status(401)
    |> render("401.json", %{reason: reason})
  end
end

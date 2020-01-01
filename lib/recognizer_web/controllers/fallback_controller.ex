defmodule RecognizerWeb.FallbackController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.ErrorView

  @behaviour Guardian.Plug.ErrorHandler

  @impl true
  def auth_error(conn, reason, _opts), do: call(conn, reason)

  @impl true
  def call(conn, {:error, reason}),
    do: render_auth_error(conn, reason)

  def call(conn, :invalid_audience),
    do: render_auth_error(conn, "missing or invalid api token")

  def call(conn, {:invalid_token, _reason}),
    do: render_auth_error(conn, "missing or invalid access token")

  def call(conn, {:no_resource_found, _reason}),
    do: render_auth_error(conn, "invalid authenticated resource")

  def call(conn, {:unauthenticated, _reason}),
    do: render_auth_error(conn, "unauthorized request")

  defp render_auth_error(conn, reason) do
    conn
    |> put_view(ErrorView)
    |> put_status(401)
    |> render("401.json", %{reason: reason})
  end
end

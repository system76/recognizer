defmodule RecognizerWeb.FallbackController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.Authentication

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:already_authenticated, _reason}, _) do
    conn
    |> redirect(to: Routes.user_settings_path(conn, :edit))
    |> halt()
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:unauthenticated, _reason}, _) do
    conn
    |> put_flash(:error, "You must log in to access this page.")
    |> Authentication.maybe_store_return_to()
    |> redirect(to: Routes.user_session_path(conn, :new))
    |> halt()
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _) do
    IO.inspect({type, reason}, label: "error")
    respond(conn, :unauthorized, "401")
  end

  defp respond(conn, type, template) do
    extension = if json?(conn), do: "json", else: "html"

    conn
    |> put_status(type)
    |> put_layout({RecognizerWeb.LayoutView, "app.html"})
    |> put_view(RecognizerWeb.ErrorView)
    |> render("#{template}.#{extension}", %{})
    |> halt()
  end

  defp json?(conn) do
    conn
    |> Plug.get_req_header("accept")
    |> String.includes?("json")
  rescue
    _ -> false
  end
end

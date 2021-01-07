defmodule RecognizerWeb.FallbackController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.Authentication

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:already_authenticated, _reason}, _) do
    conn
    |> redirect(Authentication.login_redirect(conn))
    |> halt()
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:unauthenticated, _reason}, _) do
    conn
    |> Authentication.maybe_store_return_to()
    |> redirect(to: Routes.user_session_path(conn, :new))
    |> halt()
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _) do
    respond(conn, :unauthorized, "401")
  end

  defp respond(conn, :not_found, _template) do
    if Application.get_env(:recognizer, :redirect_url) do
      redirect(conn, external: Application.get_env(:recognizer, :redirect_url))
    else
      redirect(conn, to: Routes.homepage_path(conn, :index))
    end
  end

  defp respond(conn, type, template) do
    extension = if json?(conn), do: "json", else: "html"

    conn
    |> put_status(type)
    |> put_layout({RecognizerWeb.LayoutView, "error.html"})
    |> put_view(RecognizerWeb.ErrorView)
    |> render("#{template}.#{extension}", %{})
    |> halt()
  end

  defp json?(conn) do
    conn
    |> Plug.Conn.get_req_header("accept")
    |> String.contains?("json")
  rescue
    _ -> false
  end
end

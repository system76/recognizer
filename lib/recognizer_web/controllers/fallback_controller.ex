defmodule RecognizerWeb.FallbackController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.{Authentication, ErrorView}

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:already_authenticated, _reason}, _) do
    conn
    |> redirect(Authentication.login_redirect(conn, Authentication.fetch_current_user(conn)))
    |> halt()
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:unauthenticated, _reason}, _) do
    call(conn, {:error, :unauthenticated})
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {:invalid_token, _reason}, _) do
    if json?(conn) do
      respond(conn, :unauthorized, "401")
    else
      conn
      |> Recognizer.Guardian.Plug.sign_out()
      |> fetch_session()
      |> clear_session()
      |> call({:error, :unauthenticated})
    end
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _) do
    respond(conn, :unauthorized, "401")
  end

  @impl true
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:bad_request)
    |> put_view(ErrorView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :unauthenticated}) do
    conn
    |> Authentication.maybe_store_return_to()
    |> redirect(to: Routes.user_session_path(conn, :new))
    |> halt()
  end

  def call(conn, {:error, _}) do
    conn
    |> put_status(500)
    |> put_view(ErrorView)
    |> render("500.html")
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
    |> Enum.any?(&String.contains?(&1, "json"))
  rescue
    _ -> false
  end
end

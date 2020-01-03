defmodule RecognizerWeb.AccountController do
  use RecognizerWeb, :controller

  alias Recognizer.{Accounts, Guardian}
  alias RecognizerWeb.FallbackController

  action_fallback FallbackController

  def create(conn, %{"data" => attrs}) do
    with {:ok, new_user} <- Accounts.create(attrs) do
      render_new_user(conn, new_user)
    end
  end

  def update(conn, %{"data" => attrs}) do
    user = current_user(conn)

    with {:ok, updated_user} <- Accounts.update(user, attrs) do
      render_user(conn, updated_user)
    end
  end

  def show(conn, _params) do
    user = current_user(conn)
    render_user(conn, user)
  end

  defp current_user(conn), do: Guardian.Plug.current_resource(conn)

  defp render_new_user(conn, user) do
    conn
    |> put_status(201)
    |> render_user(user)
  end

  defp render_user(conn, user) do
    render(conn, "show.json", user: user)
  end
end

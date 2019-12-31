defmodule RecognizerWeb.UsersController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.FallbackController
  alias Recognizer.Guardian

  action_fallback FallbackController

  def me(conn, _params) do
    render(conn, "me.json", user: current_user(conn))
  end

  defp current_user(conn), do: Guardian.Plug.current_resource(conn)
end

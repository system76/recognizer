defmodule RecognizerWeb.Accounts.Prompt.VerificationController do
  use RecognizerWeb, :controller

  plug :ensure_user

  def new(conn, _params) do
    render(conn, "new.html", user: conn.assigns.user)
  end
end

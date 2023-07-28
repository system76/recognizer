defmodule RecognizerWeb.Accounts.Prompt.VerificationController do
  use RecognizerWeb, :controller

  alias RecognizerWeb.Authentication

  plug :ensure_user

  def new(%{assigns: %{user: %{verified_at: nil}}} = conn, _params) do
    render(conn, "new.html")
  end

  def new(%{assigns: %{user: user}} = conn, _params) do
    Authentication.log_in_user(conn, user)
  end
end

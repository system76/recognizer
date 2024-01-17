defmodule RecognizerWeb.Controllers.Helpers do
  @moduledoc """
  Helper functions for controllers.
  """
  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  import Plug.Conn, only: [get_session: 2, assign: 3]

  def get_email_from_request(conn) do
    String.downcase(conn.params["user"]["email"] || "")
  end

  def get_user_id_from_request(conn) do
    Authentication.fetch_current_user(conn).id
  end

  def get_user_id_from_unverified_request(conn) do
    conn.assigns.user.id
  end

  def ensure_user(conn, _opts) do
    user_id = get_session(conn, :prompt_user_id)

    if user_id == nil do
      RecognizerWeb.FallbackController.call(conn, {:error, :unauthenticated})
    else
      user = Accounts.get_user!(user_id)
      assign(conn, :user, user)
    end
  end
end

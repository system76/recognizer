defmodule RecognizerWeb.Controllers.Helpers do
  @moduledoc """
  Helper functions for controllers.
  """
  alias RecognizerWeb.Authentication

  def get_email_from_request(conn) do
    conn.params["user"]["email"]
  end

  def get_user_id_from_request(conn) do
    Authentication.fetch_current_user(conn).id
  end
end

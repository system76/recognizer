defmodule RecognizerWeb.Controllers.Helpers do
  @moduledoc """
  Helper functions for controllers.
  """
  def get_email_from_request(conn) do
    conn.params["user"]["email"]
  end
end

defmodule RecognizerWeb.Controllers.Helpers do
  def get_email_from_request(conn) do
    conn.params["user"]["email"]
  end
end

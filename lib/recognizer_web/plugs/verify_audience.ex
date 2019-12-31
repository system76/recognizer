defmodule RecognizerWeb.Plugs.VerifyAudience do
  import Plug.Conn

  alias RecognizerWeb.AuthController
  alias Recognizer.Audiences

  def init(opts), do: opts

  def call(conn, opts) do
    with [token] <- get_req_header(conn, "x-recognizer-token"),
         %{id: audience_id} <- Audiences.by_token(token) do
      assign(conn, :audience_id, audience_id)
    else
      _ ->
        AuthController.auth_error(conn, {:invalid_audience, :invalid_audience}, opts)
    end
  end
end

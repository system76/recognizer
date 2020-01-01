defmodule RecognizerWeb.Plugs.VerifyAudience do
  @moduledoc """
  Verify the request has a `x-recognizer-token` and that it belongs to an Audience resource
  """
  import Plug.Conn

  alias Recognizer.Audiences
  alias RecognizerWeb.FallbackController

  def init(opts), do: opts

  def call(conn, _opts) do
    with [token] <- get_req_header(conn, "x-recognizer-token"),
         %{id: audience_id} <- Audiences.by_token(token) do
      assign(conn, :audience_id, audience_id)
    else
      _reason ->
        FallbackController.call(conn, :invalid_audience)
    end
  end
end

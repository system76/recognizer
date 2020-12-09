defmodule RecognizerWeb.HealthcheckPlug do
  @moduledoc """
  A simple plug that listens at the `/_health` url and responds 200. This is a
  plug instead of a controller to avoid ending up in the logs.
  """

  import Plug.Conn

  @behaviour Plug
  @url "/_health"

  def init(opts), do: opts

  def call(%{request_path: @url} = conn, _opts) do
    conn
    |> send_resp(200, "ok")
    |> halt()
  end

  def call(conn, _opts), do: conn
end

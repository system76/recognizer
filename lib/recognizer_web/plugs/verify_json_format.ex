defmodule RecognizerWeb.Plugs.VerifyJSONFormat do
  @moduledoc """
  Verfiy JSON payloads are nested under a `data` key
  """

  import Plug.Conn

  alias RecognizerWeb.ErrorView

  def init(opts), do: opts

  def call(%{method: method} = conn, _opts) when method in ["DELETE", "GET"] do
    conn
  end

  def call(%{params: %{"data" => _}} = conn, _opts) do
    conn
  end

  def call(conn, _opts) do
    conn
    |> put_status(400)
    |> Phoenix.Controller.put_view(ErrorView)
    |> Phoenix.Controller.render("400.json", %{reason: "invalid JSON formatting"})
  end
end

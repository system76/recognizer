defmodule RecognizerWeb.AuthPlug do
  @moduledoc """
  `Guardian.Plug.Pipeline` for verifying JWT tokens in the session and header.
  """

  require Logger

  use Guardian.Plug.Pipeline,
    otp_app: :recognizer,
    module: Recognizer.Guardian,
    error_handler: RecognizerWeb.FallbackController

  plug Guardian.Plug.VerifySession, claims: %{"iss" => "system76", "typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"iss" => "system76", "typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true

  plug :set_metadata

  defp set_metadata(conn, _params) do
    if user = Guardian.Plug.current_resource(conn) do
      Logger.metadata(user_id: user.id)
    end

    conn
  end
end

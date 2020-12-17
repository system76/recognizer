defmodule RecognizerWeb.AuthPlug do
  @moduledoc """
  `Guardian.Plug.Pipeline` for verifying JWT tokens in the session and header.
  """

  use Guardian.Plug.Pipeline,
    otp_app: :recognizer,
    module: Recognizer.Guardian,
    error_handler: RecognizerWeb.FallbackController

  plug Guardian.Plug.VerifySession, claims: %{"iss" => "system76", "typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"iss" => "system76", "typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end

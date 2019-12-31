defmodule RecognizerWeb.Plugs.AuthenticationPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :recognizer,
    error_handler: RecognizerWeb.AuthController,
    module: Recognizer.Guardian

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end

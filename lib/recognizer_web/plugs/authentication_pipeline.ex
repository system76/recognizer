defmodule RecognizerWeb.Plugs.AuthenticationPipeline do
  @moduledoc """
  The collection of plugs that constitutes our authentication pipeline
  """

  use Guardian.Plug.Pipeline,
    otp_app: :recognizer,
    error_handler: RecognizerWeb.FallbackController,
    module: Recognizer.Guardian

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end

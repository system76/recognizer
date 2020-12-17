defmodule Recognizer.Endpoint do
  @moduledoc """
  Endpoint for the gRPC server used for internal network communication.
  """

  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run Recognizer.Server
end

defmodule Recognizer.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(Recognizer.Server)
end

defmodule Recognizer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Recognizer.Repo,
      # Start the Telemetry supervisor
      RecognizerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Recognizer.PubSub},
      # Start the gRPC server for internal requests
      supervisor(GRPC.Server.Supervisor, [{Recognizer.Endpoint, 50_051}]),
      # Start the DB sweeper to remove old keys
      {Guardian.DB.Token.SweeperServer, []},
      # Start the Endpoint (http/https)
      RecognizerWeb.Endpoint
      # Start a worker by calling: Recognizer.Worker.start_link(arg)
      # {Recognizer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Recognizer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RecognizerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

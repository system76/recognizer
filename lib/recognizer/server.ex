defmodule Recognizer.Server do
  @moduledoc """
  gRPC server for `Bottle.Account.V1.Server`.
  """

  use GRPC.Server, service: Bottle.Account.V1.Service
  use Spandex.Decorators

  alias Bottle.Account.V1.NotificationMethodResponse
  alias Recognizer.Accounts

  @decorate trace(name: "gRPC Bottle.Account.V1.NotificationMethod")
  def notification_method(%{event_type: event_type, user: req_user} = request, _stream) do
    Bottle.RequestId.read(:rpc, request)

    event_type = String.to_existing_atom(event_type)
    user = Accounts.get_user!(req_user.id)
    preference = get_in(user, [:notification_preference, event_type])

    %NotificationMethodResponse{
      request_id: Bottle.RequestId.write(:rpc),
      notification_method: Recognizer.Bottle.convert_notification_method(preference),
      user: Recognizer.Bottle.convert_user(user)
    }
  end
end

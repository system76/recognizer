defmodule Recognizer.Server do
  use GRPC.Server, service: Bottle.Account.V1.Service

  alias Bottle.Account.V1.{NotificationMethodResponse, User}
  alias GRPC.Server
  alias Recognizer.Account

  def notification_method(%{event_type: event_type, user: req_user} = request) do
    Bottle.RequestId.read(:rpc, request)

    user = Account.get_user!(req_user.id)

    # TODO: Get notification method for event type

    %NotificationMethodResponse{
      request_id: Bottle.RequestId.write(:rpc),
      notification_method: "NOTIFICATION_METHOD_UNSPECIFIED",
      user: convert_user(user)
    }
  end

  defp convert_user(user) do
    user
    |> Map.take(~w(id first_name last_name email)a)
    |> User.new()
  end
end

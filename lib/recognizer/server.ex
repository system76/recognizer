defmodule Recognizer.Server do
  @moduledoc """
  gRPC server for `Bottle.Account.V1.Server`.
  """

  use GRPC.Server, service: Bottle.Account.V1.Service

  alias Bottle.Account.V1.{NotificationMethodResponse, User}
  alias GRPC.Server
  alias Recognizer.Accounts

  def notification_method(%{event_type: event_type, user: req_user} = request, _stream) do
    Bottle.RequestId.read(:rpc, request)

    user = Accounts.get_user!(req_user.id)

    %NotificationMethodResponse{
      request_id: Bottle.RequestId.write(:rpc),
      notification_method: :NOTIFICATION_METHOD_UNSPECIFIED,
      user: convert_user(user)
    }
  end

  defp convert_user(user) do
    User.new(
      email: user.email,
      first_name: user.first_name,
      id: to_string(user.id),
      last_name: user.last_name
    )
  end
end

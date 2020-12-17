defmodule Recognizer.Server do
  @moduledoc """
  gRPC server for `Bottle.Account.V1.Server`.
  """

  use GRPC.Server, service: Bottle.Account.V1.Service

  alias Bottle.Account.V1.{NotificationMethodResponse, User}
  alias Recognizer.Accounts

  def notification_method(%{event_type: event_type, user: req_user} = request, _stream) do
    Bottle.RequestId.read(:rpc, request)

    event_type = String.to_existing_atom(event_type)
    user = Accounts.get_user!(req_user.id)
    preference = get_in(user, [:notification_preference, event_type])

    %NotificationMethodResponse{
      request_id: Bottle.RequestId.write(:rpc),
      notification_method: convert_notification_method(preference),
      user: convert_user(user)
    }
  end

  defp convert_notification_method(:app), do: :NOTIFICATION_METHOD_APP
  defp convert_notification_method(:email), do: :NOTIFICATION_METHOD_EMAIL
  defp convert_notification_method(:text), do: :NOTIFICATION_METHOD_TEXT
  defp convert_notification_method(:voice), do: :NOTIFICATION_METHOD_VOICE
  defp convert_notification_method(_), do: :NOTIFICATION_METHOD_UNSPECIFIED

  defp convert_user(user) do
    User.new(
      email: user.email,
      first_name: user.first_name,
      id: to_string(user.id),
      last_name: user.last_name
    )
  end
end

defmodule Recognizer.Notifications.Account do
  @moduledoc """
  Sends notifications related to user account activites. Right now this logs to
  console, but in the future this will put messages into a queue for our
  notification microservice to deliver.
  """

  use Spandex.Decorators

  alias Bottle.Account.V1, as: Account

  # credo:disable-for-next-line
  @enabled Application.get_env(:ex_aws, :enabled)

  @doc """
  Deliver user creation welcome message.
  """
  def deliver_user_created_message(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.UserCreated)
    |> send_message(:user_created)
  end

  @doc """
  Deliver user password changed notification.
  """
  def deliver_user_password_changed_notification(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.PasswordChanged)
    |> send_message(:password_changed)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.PasswordReset, reset_url: url)
    |> send_message(:password_reset)
  end

  @doc """
  Deliver the two factor two to the user.
  """
  def deliver_two_factor_token(user, token) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.TwoFactorRequested, token: token)
    |> send_message(:two_factor_requested)
  end

  @doc """
  Deliver user recovery code used notification.
  """
  def deliver_user_recovery_code_used_notification(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.RecoveryCodeUsed)
    |> send_message(:recovery_code_used)
  end

  defp create_message(user, type, args \\ []) do
    apply(type, :new, [Keyword.merge([user: user], args)])
  end

  defp encode_message(resource, atom) do
    message_in_a_bottle =
      Bottle.Core.V1.Bottle.new(
        request_id: Bottle.RequestId.write(:http),
        resource: {atom, resource},
        source: "recognizer",
        timestamp: DateTime.to_unix(DateTime.utc_now())
      )

    message_in_a_bottle
    |> Bottle.Core.V1.Bottle.encode()
    |> URI.encode()
  end

  defp message_queue_url(%message_type{}) do
    :recognizer
    |> Application.get_env(:message_queues)
    |> Keyword.get(message_type)
  end

  @decorate span(service: :bullhorn, type: :function)
  defp send_message(resource, atom) when @enabled do
    encoded_message = encode_message(resource, atom)

    resource
    |> message_queue_url()
    |> send_message_to_queue(encoded_message)

    {:ok, resource}
  end

  defp send_message(resource, _atom) do
    {:ok, resource}
  end

  defp send_message_to_queue(queues, message) when is_list(queues) do
    Enum.each(queues, &send_message_to_queue(&1, message))
  end

  defp send_message_to_queue(queue, message) do
    queue
    |> ExAws.SQS.send_message(message)
    |> ExAws.request()
  end
end

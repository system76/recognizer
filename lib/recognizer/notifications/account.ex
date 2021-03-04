defmodule Recognizer.Notifications.Account do
  @moduledoc """
  Sends notifications related to user account activites. Right now this logs to
  console, but in the future this will put messages into a queue for our
  notification microservice to deliver.
  """

  alias Bottle.Account.V1, as: Account

  @doc """
  Deliver user creation welcome message.
  """
  def deliver_user_created_message(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.UserCreated)
    |> send_message()
  end

  @doc """
  Deliver user updated message.
  """
  def deliver_user_updated_message(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.UserUpdated)
    |> send_message()
  end

  @doc """
  Deliver user deleted message.
  """
  def deliver_user_deleted_message(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.UserDeleted)
    |> send_message()
  end

  @doc """
  Deliver user password changed notification.
  """
  def deliver_user_password_changed_notification(user) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.PasswordChanged)
    |> send_message()
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.PasswordReset, reset_url: url)
    |> send_message()
  end

  @doc """
  Deliver the two factor two to the user.
  """
  def deliver_two_factor_token(user, token, method) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.TwoFactorRequested, token: token, method: two_factor_method(method))
    |> send_message()
  end

  def two_factor_method(:text), do: :TWO_FACTOR_METHOD_SMS
  def two_factor_method(:voice), do: :TWO_FACTOR_METHOD_VOICE

  @doc """
  Deliver user recovery code used notification.
  """
  def deliver_user_recovery_code_used_notification(user, recovery_code_used, codes_remaining) do
    user
    |> Recognizer.Bottle.convert_user()
    |> create_message(Account.TwoFactorRecoveryCodeUsed,
      recovery_code: recovery_code_used,
      codes_remaining: length(codes_remaining)
    )
    |> send_message()
  end

  defp create_message(user, type, args \\ []) do
    apply(type, :new, [Keyword.merge([user: user], args)])
  end

  if Application.compile_env(:ex_aws, :enabled) do
    use Spandex.Decorators

    @decorate span(service: :bullhorn, type: :function)
    defp send_message(resource) do
      Bottle.publish(resource, source: "recognizer", request_id: Bottle.RequestId.write(:http))

      {:ok, resource}
    end
  else
    defp send_message(resource, _atom) do
      {:ok, resource}
    end
  end
end

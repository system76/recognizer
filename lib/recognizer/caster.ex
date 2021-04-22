defmodule Recognizer.Caster do
  @moduledoc """
  Helper utilities for converting to `Bottle` records.
  """

  alias Bottle.Account.V1, as: Account

  def cast(user) do
    Account.User.new(
      account_type: convert_user_type(user.type),
      company_name: user.company_name,
      email: user.email,
      first_name: user.first_name,
      id: to_string(user.id),
      last_name: user.last_name,
      phone_number: user.phone_number
    )
  end

  defp convert_user_type(type) do
    case type do
      :individual -> :ACCOUNT_TYPE_INDIVIDUAL
      :business -> :ACCOUNT_TYPE_BUSINESS
      _ -> :ACCOUNT_TYPE_UNSPECIFIED
    end
  end
end

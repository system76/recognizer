defmodule Recognizer.Bottle do
  @moduledoc """
  Helper utilities for converting to `Bottle` records.
  """

  alias Bottle.Account.V1, as: Account

  def convert_user(user) do
    user
    |> Map.take([:first_name, :last_name, :email, :phone_number, :company_name, :newsletter])
    |> Map.put(:id, to_string(user.id))
    |> Map.put(:account_type, convert_user_type(user.type))
    |> Account.User.new()
  end

  defp convert_user_type(type) do
    case type do
      :individual -> :ACCOUNT_TYPE_INDIVIDUAL
      :business -> :ACCOUNT_TYPE_BUSINESS
      _ -> :ACCOUNT_TYPE_UNSPECIFIED
    end
  end
end

defmodule Recognizer.Guardian do
  @moduledoc """
  Implements the necessary functionality for our Guardian usage.
  """
  use Guardian, otp_app: :recognizer

  alias Recognizer.Accounts

  @doc """
  Return the `sub` value from a given resource for use in a JWT
  """
  def subject_for_token(%{id: user_id}, _claims) do
    {:ok, to_string(user_id)}
  end

  @doc """
  Return a resource from a `sub` value
  """
  def resource_from_claims(%{"sub" => user_id}) do
    with {int_user_id, _} <- Integer.parse(user_id),
         %{id: ^int_user_id} = user <- Accounts.get_by(id: int_user_id) do
      {:ok, user}
    else
      _ -> {:error, :no_resource_found}
    end
  end

  @doc """
  Verify our `aud` and `sub` claims based on their presence in our token
  """
  def verify_claims(%{"aud" => aud, "sub" => sub} = claims, opts) do
    if verified_claim?(aud, opts, :aud) and verified_claim?(sub, opts, :sub) do
      {:ok, claims}
    else
      {:error, "unable to verify claims"}
    end
  end

  defp verified_claim?(expected_value, claims, claim) do
    actual_value = Keyword.get(claims, claim)
    is_nil(actual_value) or expected_value == actual_value
  end
end

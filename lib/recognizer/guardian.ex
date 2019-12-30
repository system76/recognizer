defmodule Recognizer.Guardian do
  use Guardian, otp_app: :recognizer

  alias Recognizer.Accounts

  def subject_for_token(%{id: user_id}, _claims) do
    {:ok, to_string(user_id)}
  end

  def resource_from_claims(%{"sub" => user_id}) do
    {int_user_id, _} = Integer.parse(user_id)
    Accounts.get_by(id: int_user_id)
  end

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

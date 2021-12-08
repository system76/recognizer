defmodule Recognizer.Guardian do
  @moduledoc """
  All functions related to JWT reading and writing.
  """

  use Guardian, otp_app: :recognizer

  alias Guardian.DB
  alias Recognizer.Accounts

  def subject_for_token(%Recognizer.Accounts.User{id: id}, _claims) do
    {:ok, "user:" <> to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :unhandled_resource_type}
  end

  def resource_from_claims(%{"sub" => "user:" <> user_id}) do
    {:ok, Accounts.get_user!(user_id)}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end

  def resource_from_claims(_) do
    {:error, :unhandled_resource_type}
  end

  def encode_and_sign_access_token(access_token) do
    user = Keyword.get(access_token, :resource_owner)

    scopes =
      access_token
      |> Keyword.get(:scopes, [])
      |> String.split(" ")

    {:ok, token, _claims} = encode_and_sign(user, %{scopes: scopes}, token_type: "access")

    token
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end

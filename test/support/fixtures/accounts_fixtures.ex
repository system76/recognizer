defmodule Recognizer.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Recognizer.Accounts` context.
  """

  def unique_name, do: "personnum#{System.unique_integer()}"
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "aBcD123%&^"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        first_name: unique_name(),
        last_name: unique_name(),
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Recognizer.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.reset_url, "[TOKEN]")
    token
  end
end

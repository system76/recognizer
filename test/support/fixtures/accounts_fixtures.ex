defmodule Recognizer.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the
  `Recognizer.Accounts` context.
  """

  use ExMachina.Ecto, repo: Recognizer.Repo

  alias Recognizer.Accounts

  def email_factory(_attrs), do: sequence(:email, &"example#{&1}@example.com")
  def password_factory(_attrs), do: sequence(:password, &"aBcD123%&^#{&1}")

  def notification_preference_factory do
    %Accounts.NotificationPreference{
      two_factor: :text
    }
  end

  def organization_factory do
    %Accounts.Organization{
      name: sequence(:name, &"organization-#{&1}")
    }
  end

  def user_factory(attrs) do
    password = Map.get(attrs, :password, build(:password))
    password_changed_at = Map.get(attrs, :password_changed_at, NaiveDateTime.utc_now())

    %Accounts.User{
      first_name: sequence(:first_name, &"first-name-#{&1}"),
      last_name: sequence(:last_name, &"last-name-#{&1}"),
      email: build(:email),
      username: sequence(:username, &"example-at-examp#{&1}"),
      phone_number: sequence(:phone_number, &"+18000000000-#{&1}"),
      type: :individual,
      newsletter: false,
      password: password,
      hashed_password: Argon2.hash_pwd_salt(password),
      notification_preference: build(:notification_preference),
      password_changed_at: password_changed_at
    }
  end

  def add_two_factor(user, type \\ :text) do
    seed = Recognizer.Accounts.generate_new_two_factor_seed()

    %{
      user
      | notification_preference: build(:notification_preference, two_factor: type),
        recovery_codes: Recognizer.Accounts.generate_new_recovery_codes(user),
        two_factor_enabled: true,
        two_factor_seed: seed
    }
  end

  def add_organization_policy(user, attrs \\ []) do
    %{id: org_id} = insert(:organization, attrs)
    %{user | organization_id: org_id}
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.reset_url, "[TOKEN]")
    token
  end
end

defmodule Recognizer.Factories do
  @moduledoc false
  use ExMachina.Ecto, repo: Recognizer.Repo

  alias Recognizer.Schemas.{Audience, Role, User}

  def audience_factory do
    %Audience{
      name: "Test audience",
      token: sequence(:audience_token, &"audience_token-#{&1}")
    }
  end

  def role_factory do
    %Role{
      name: "login",
      description: "Description for the Role"
    }
  end

  def user_factory do
    %User{
      email: sequence(:email, &"user-#{&1}@system76.com"),
      password_hash: Recognizer.Auth.hash_password("password"),
      avatar_filename: sequence(:avatar_filename, &"http://example.com/img/#{&1}.png"),
      company_name: "Test Company",
      first_name: "Test",
      last_name: "User",
      phone_number: sequence(:phone_number, &"+1(111)111-111#{&1}"),
      type: "individual",
      username: "Tester"
    }
  end

  def add_role(user, role) do
    user
    |> Recognizer.Repo.preload(:roles)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:roles, [role])
    |> Recognizer.Repo.update!()
  end
end

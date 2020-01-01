defmodule Recognizer.AccountsTest do
  use Recognizer.DataCase

  import Recognizer.Factories

  alias Recognizer.{Accounts, Schemas.User}

  describe "create/1" do
    test "returns a newly created User resource" do
      attrs =
        :user
        |> string_params_for()
        |> Map.put("password", "p@ssw0Rd!")
        |> Map.put("password_confirmation", "p@ssw0Rd!")

      assert {:ok, _user} = Accounts.create(attrs)
    end
  end

  describe "get_by/1" do
    test "returns a user by their email with their roles" do
      email = "existing@system76.com"
      insert(:user, %{email: email})
      assert %User{email: ^email} = Accounts.get_by(email: email)
    end

    test "returns a user by their id with their roles" do
      %{id: user_id} = insert(:user)
      assert %User{id: ^user_id} = Accounts.get_by(id: user_id)
    end

    test "returns an error for missing users" do
      assert is_nil(Accounts.get_by(email: "nonexistant@system76.com"))
    end
  end

  describe "update/2" do
    test "returns the updated resource" do
      user = insert(:user, first_name: "Unchanged")
      assert {:ok, %{first_name: "Changed"}} = Accounts.update(user, %{"first_name" => "Changed"})
    end

    test "returns the updated resource when password changes are valid" do
      changes = %{"password" => "p@ssw0Rd!", "password_confirmation" => "p@ssw0Rd!"}

      %{password_hash: unchanged_password_hash} = user = insert(:user)
      assert {:ok, %{password_hash: changed_password_hash}} = Accounts.update(user, changes)
      assert unchanged_password_hash != changed_password_hash
    end
  end
end

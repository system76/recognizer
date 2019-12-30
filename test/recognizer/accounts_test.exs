defmodule Recognizer.AccountsTest do
  use Recognizer.DataCase

  import Recognizer.Factories

  alias Recognizer.{Accounts, Schemas.User}

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
end

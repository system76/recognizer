defmodule Recognizer.CasterTest do
  use ExUnit.Case

  import Recognizer.AccountFactory

  alias Recognizer.Caster

  describe "cast/1" do
    test "returns a bottled user" do
      assert %Bottle.Account.V1.User{
               account_type: :ACCOUNT_TYPE_BUSINESS,
               email: "test@example.com",
               first_name: "Test",
               last_name: "User"
             } =
               :user
               |> build(first_name: "Test", last_name: "User", email: "test@example.com", type: :business)
               |> Caster.cast()
    end
  end
end

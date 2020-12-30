defmodule Recognizer.Accounts.UserTest do
  use Recognizer.DataCase

  alias Recognizer.Accounts.User

  describe "two_factor_changeset/2" do
    test "sets a new two factor seed and recovery codes when updated" do
      %{changes: changes} = changeset = User.two_factor_changeset(%User{}, %{two_factor_enabled: true})

      assert changeset.valid?
      assert 12 == length(changes.recovery_codes)
      assert changes.two_factor_seed
    end
  end
end

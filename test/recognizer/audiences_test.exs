defmodule Recognizer.AudiencesTest do
  use Recognizer.DataCase

  import Recognizer.Factories

  alias Recognizer.Audiences

  describe "by_token/1" do
    test "returns the Audience resource for a given token" do
      %{id: id, token: token} = insert(:audience)
      assert %{id: ^id} = Audiences.by_token(token)
    end

    test "return an error when no Audience resource is found" do
      assert is_nil(Audiences.by_token("a missing token"))
    end
  end
end

defmodule Recognizer.Schemas.UserTest do
  use ExUnit.Case

  import Recognizer.Factories

  alias Recognizer.Schemas.User

  describe "changeset/2" do
    setup do
      attrs =
        :user
        |> string_params_for()
        |> Map.put("password", "p@ssw0Rd!")
        |> Map.put("password_confirmation", "p@ssw0Rd!")

      {:ok, valid_attrs: attrs}
    end

    test "returns a valid changeset", %{valid_attrs: attrs} do
      assert %{valid?: true} = User.changeset(%User{}, attrs)
    end

    test "returns an invalid changeset when missing required fields", %{valid_attrs: attrs} do
      invalid_attrs = Map.drop(attrs, ["email"])

      assert %{valid?: false, errors: [email: {"can't be blank", [validation: :required]}]} =
               User.changeset(%User{}, invalid_attrs)
    end

    test "returns an invalid changeset for weak passwords", %{valid_attrs: attrs} do
      weak_password = "pass"

      invalid_attrs =
        attrs
        |> Map.put("password", weak_password)
        |> Map.put("password_confirmation", weak_password)

      assert %{
               valid?: false,
               errors: [
                 password: {"must contain a symbol or space", [validation: :format]},
                 password: {"must contain an UPPERCASE letter", [validation: :format]},
                 password: {"must contain a number", [validation: :format]},
                 password:
                   {"should be at least %{count} character(s)",
                    [count: 8, validation: :length, kind: :min, type: :string]}
               ]
             } = User.changeset(%User{}, invalid_attrs)
    end
  end
end

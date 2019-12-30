defmodule Recognizer.Schemas.Role do
  use Ecto.Schema

  schema "roles" do
    field :name, :string
    field :description, :string

    timestamps()
  end
end

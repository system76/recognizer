defmodule Recognizer.Schemas.Audience do
  use Ecto.Schema

  schema "audiences" do
    field :name, :string
    field :token, :string

    timestamps()
  end
end

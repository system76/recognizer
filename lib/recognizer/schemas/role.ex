defmodule Recognizer.Schemas.Role do
  @moduledoc """
  A user's role within the system
  """

  use Ecto.Schema

  schema "roles" do
    field :name, :string
    field :description, :string

    timestamps()
  end
end

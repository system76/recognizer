defmodule Recognizer.Schemas.Audience do
  @moduledoc """
  The audience, or consuming application/service, of an authentication token
  """
  use Ecto.Schema

  schema "audiences" do
    field :name, :string
    field :token, :string

    timestamps()
  end
end

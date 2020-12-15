defmodule Recognizer.Accounts.OAuth do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User
  alias __MODULE__, as: OAuth

  schema "user_oauths" do
    field :service, :string
    field :service_guid, :string

    belongs_to :user, User
  end

  def changeset(%OAuth{} = oauth, attrs \\ %{}) do
    oauth
    |> cast(attrs, [:service, :service_guid, :user_id])
    |> validate_required([:service, :service_guid])
    |> validate_inclusion(:service, ["github", "google"])
    |> assoc_constraint(:user)
  end
end

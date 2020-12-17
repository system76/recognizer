defmodule Recognizer.Accounts.NotificationPreference do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User
  alias __MODULE__, as: NotificationPreference

  schema "notification_preferences" do
    field :two_factor, Recognizer.TwoFactorPreference, default: :text

    belongs_to :user, User

    timestamps()
  end

  def changeset(%NotificationPreference{} = oauth, attrs \\ %{}) do
    oauth
    |> cast(attrs, [:two_factor, :user_id])
    |> assoc_constraint(:user)
  end
end

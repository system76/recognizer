defmodule Recognizer.Accounts.NotificationPreference do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.User
  alias __MODULE__, as: Notification

  schema "notification_preferences" do
    field :two_factor, Recognizer.TwoFactorPreference, default: :text

    belongs_to :user, User
  end

  def changeset(%Notification{} = oauth, attrs \\ %{}) do
    oauth
    |> cast(attrs, [:two_factor, :user_id])
    |> assoc_constraint(:user)
  end
end

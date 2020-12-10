defmodule Recognizer.OauthProvider.AccessGrant do
  @moduledoc """
  `Ecto.Schema` for all oauth2 grants made by a user for an application.
  """

  use Ecto.Schema

  alias Recognizer.{Accounts, OauthProvider}

  schema "oauth_access_grants" do
    field :token, :string, null: false
    field :redirect_uri, :string, null: false
    field :scopes, :string

    belongs_to :resource_owner, Accounts.User
    belongs_to :application, OauthProvider.Application

    field :expires_in, :integer, null: false
    field :revoked_at, :utc_datetime
    timestamps()
  end
end

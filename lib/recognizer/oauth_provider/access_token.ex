defmodule Recognizer.OauthProvider.AccessToken do
  @moduledoc """
  `Ecto.Schema` for all oauth2 access tokens granted in our application
  """

  use Ecto.Schema

  alias Recognizer.{Accounts, OauthProvider}

  schema "oauth_access_tokens" do
    field :token, :string, null: false
    field :refresh_token, :string
    field :scopes, :string
    field :previous_refresh_token, :string, null: false, default: ""

    belongs_to :resource_owner, Accounts.User
    belongs_to :application, OauthProvider.Application

    field :expires_in, :integer
    field :revoked_at, :utc_datetime
    timestamps()
  end
end

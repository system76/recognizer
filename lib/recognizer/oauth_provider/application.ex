defmodule Recognizer.OauthProvider.Application do
  @moduledoc """
  `Ecto.Schema` for all oauth2 application that can authorize on our accounts.
  """

  use Ecto.Schema

  alias Recognizer.{Accounts, OauthProvider}

  schema "oauth_applications" do
    field :name, :string, null: false
    field :uid, :string, null: false
    field :secret, :string, null: false, default: ""
    field :redirect_uri, :string, null: false
    field :scopes, :string, null: false, default: ""
    field :privileged, :boolean, default: false

    belongs_to :owner, Accounts.User
    has_many :access_tokens, OauthProvider.AccessToken, foreign_key: :application_id

    timestamps()
  end
end

defmodule Recognizer.OauthProvider.Application do
  @moduledoc """
  `Ecto.Schema` for all oauth2 application that can authorize on our accounts.
  """

  use Ecto.Schema

  alias Recognizer.{Accounts, OauthProvider}

  schema "oauth_applications" do
    field :name, :string
    field :uid, :string
    field :secret, :string, default: ""
    field :redirect_uri, :string
    field :scopes, :string, default: ""
    field :privileged, :boolean, default: false

    belongs_to :owner, Accounts.User
    has_many :access_tokens, OauthProvider.AccessToken, foreign_key: :application_id

    timestamps()
  end
end

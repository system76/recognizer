defmodule Recognizer.Accounts.BCCustomerUser do
  @moduledoc false

  use Ecto.Schema

  alias Recognizer.Accounts.User

  @primary_key false
  schema "bigcommerce_customer_users" do
    field :bc_id, :integer
    belongs_to :user, User, primary_key: true

    timestamps()
  end
end

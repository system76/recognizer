defmodule Recognizer.Accounts do
  @moduledoc """
  The public API for our User and Role schemas
  """

  import Ecto.Query

  alias Recognizer.{Repo, Schemas.User}

  @doc """
  Look up a user via email and populate their roles
  """
  @spec get_by(keyword()) :: Repo.Schema.t() | nil
  def get_by(predicates) do
    query =
      from user in User,
        left_join: roles in assoc(user, :roles),
        preload: [:roles]

    query
    |> query_predicates(predicates)
    |> Repo.one()
  end

  defp query_predicates(query, predicates) when is_list(predicates) do
    Enum.reduce(predicates, query, &query_predicate/2)
  end

  defp query_predicate(predicate, query) do
    where(query, [user, _roles], ^[predicate])
  end
end

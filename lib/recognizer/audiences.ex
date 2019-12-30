defmodule Recognizer.Audiences do
  @moduledoc """
  The public API for our underlying Audience applications
  """

  alias Recognizer.{Repo, Schemas.Audience}

  @spec by_token(String.t()) :: Repo.Schema.t() | nil
  def by_token(token), do: Repo.get_by(Audience, token: token)
end

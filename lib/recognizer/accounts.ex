defmodule Recognizer.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Recognizer.Accounts.{User, OAuth}
  alias Recognizer.Guardian
  alias Recognizer.Notifications.Account, as: Notification
  alias Recognizer.Repo

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by a third party service login.

  ## Examples

      iex> get_user_by_service_guid("github", "1234")
      %User{}

      iex> get_user_by_service_guid("github", "nope")
      nil

  """
  def get_user_by_service_guid(service, service_guid) do
    query =
      from o in OAuth,
        join: u in assoc(o, :user),
        join: n in assoc(u, :notification_preference),
        join: r in assoc(u, :roles),
        where: o.service == ^service and o.service_guid == ^service_guid,
        preload: [user: {u, [notification_preference: n, roles: r]}]

    with %OAuth{user: user} <- Repo.one(query),
         %User{two_factor_enabled: false} <- user do
      {:ok, user}
    else
      %User{two_factor_enabled: true} = user ->
        {:two_factor, user}

      _ ->
        nil
    end
  end

  @doc """
  Creates a new third party service login for a user.
  """
  def create_oauth(user, service, service_guid) do
    attrs = %{service: service, service_guid: service_guid, user_id: user.id}

    %OAuth{}
    |> OAuth.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      {:ok, %User{}}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    query =
      from u in User,
        join: n in assoc(u, :notification_preference),
        join: r in assoc(u, :roles),
        where: u.email == ^email,
        preload: [notification_preference: n, roles: r]

    with %User{} = user <- Repo.one(query),
         true <- User.valid_password?(user, password),
         %User{two_factor_enabled: false} <- user do
      {:ok, user}
    else
      %User{two_factor_enabled: true} = user ->
        {:two_factor, user}

      _ ->
        nil
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    query =
      from u in User,
        join: n in assoc(u, :notification_preference),
        join: r in assoc(u, :roles),
        where: u.id == ^id,
        preload: [notification_preference: n, roles: r]

    Repo.one!(query)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> insert_user_and_notification_preferences()
    |> maybe_notify_new_user()
  end

  @doc """
  Registers a user from a third party service. This is different from above
  because it does not set a password, therefor only letting the user login with
  their third party account.
  """
  def register_oauth_user(attrs) do
    %User{}
    |> User.oauth_registration_changeset(attrs)
    |> insert_user_and_notification_preferences()
    |> maybe_notify_new_user()
  end

  defp insert_user_and_notification_preferences(changeset) do
    with {:ok, user} <- Repo.insert(changeset) do
      user
      |> Ecto.build_assoc(:notification_preference)
      |> Repo.insert()

      {:ok, user}
    end
  end

  defp maybe_notify_new_user({:ok, user}) do
    {:ok, _} = Notification.deliver_user_created_message(user)
    {:ok, user}
  end

  defp maybe_notify_new_user(error) do
    error
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user's basic profile settings.

  ## Examples

      iex> change_user(user, %{email: "new@example.com"})
      %User{}

  """
  def change_user(user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Updates the user's basic profile settings. This does not touch more advanced
  things like notification preferences, or password.

  ## Examples

      iex> update_user(user, %{email: "valid@example.com"})
      {:ok, %User{}}

      iex> update_user(user, %{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, _} = Notification.deliver_user_password_changed_notification(user)
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    with {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      token
    end
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    case Guardian.resource_from_token(token, %{"typ" => "access"}) do
      {:ok, user, _claims} -> user
      _ -> nil
    end
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    with {:ok, _claims} <- Guardian.revoke(token) do
      :ok
    end
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{"typ" => "reset_password"})

    Notification.deliver_reset_password_instructions(
      user,
      reset_password_url_fun.(token)
    )
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    case Guardian.resource_from_token(token, %{"typ" => "reset_password"}) do
      {:ok, user, _claims} -> user
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  defp user_and_contexts_query(user, :all) do
    {:ok, sub} = Guardian.subject_for_token(user, %{})

    from t in "users_tokens",
      where: t.sub == ^sub
  end

  defp user_and_contexts_query(user, typ) do
    {:ok, sub} = Guardian.subject_for_token(user, %{"typ" => typ})

    from t in "users_tokens",
      where: t.sub == ^sub and t.typ == ^typ
  end

  def change_user_two_factor(user, attrs \\ %{}) do
    User.two_factor_changeset(user, attrs)
  end

  @doc """
  Updates the user's two factor status and preference.

  ## Examples

  iex> update_user_two_factor(user, %{"two_factor_enabled" => true, "notification_preference" => %{"two_factor" => "app"}})
      {:ok, %User{}}

  """
  def update_user_two_factor(user, attrs) do
    user_changeset = change_user_two_factor(user, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, user_changeset)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end
end

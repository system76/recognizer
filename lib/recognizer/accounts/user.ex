defmodule Recognizer.Accounts.User do
  @moduledoc """
  `Ecto.Schema` for user records.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Recognizer.Accounts.NotificationPreference
  alias Recognizer.Repo
  alias __MODULE__

  @derive {Inspect, except: [:password]}

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, source: :password
    field :two_factor_enabled, :boolean
    field :two_factor_seed, :string

    has_one :notification_preference, NotificationPreference

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:first_name, :last_name, :email, :password])
    |> validate_required([:first_name, :last_name])
    |> validate_email()
    |> validate_password(opts)
    |> generate_username()
  end

  def oauth_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :email])
    |> validate_required([:first_name, :last_name])
    |> put_change(:hashed_password, "")
    |> validate_email()
    |> generate_username()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 80)
    |> validate_format(:password, ~r/[0-9]/, message: "must contain a number")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain an UPPERCASE letter")
    |> validate_format(:password, ~r/[a-z]/, message: "must contain a lowercase letter")
    |> validate_format(:password, ~r/[ \!\$\*\+\[\{\]\}\\\|\.\/\?,!@#%^&-=,.<>'";:]/,
      message: "must contain a symbol or space"
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp generate_username(changeset) do
    if email = get_change(changeset, :email) do
      username =
        email
        |> String.replace("@", "-at-")
        |> String.slice(0, 16)

      put_change(changeset, :username, username <> random_string(16))
    else
      changeset
    end
  end

  # NOTE: Base 16 hashes are a subset of Joshua's random strings.  Most legacy
  # hashes will not be valid base 16-encoded values
  defp random_string(length) do
    length
    |> div(2)
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A user changeset for changing the two factor preference.
  """
  def two_factor_changeset(user, attrs) do
    user
    |> cast(attrs, [:two_factor_enabled])
    |> set_two_factor_seed()
  end

  defp set_two_factor_seed(%{changes: %{two_factor_enabled: two_factor_enabled}} = changeset) do
    if two_factor_enabled do
      seed = 5 |> :crypto.strong_rand_bytes() |> Base.encode32()
      put_change(changeset, :two_factor_seed, seed)
    else
      put_change(changeset, :two_factor_seed, nil)
    end
  end

  defp set_two_factor_seed(changeset) do
    changeset
  end
end

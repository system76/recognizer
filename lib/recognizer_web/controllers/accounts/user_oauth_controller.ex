defmodule RecognizerWeb.Accounts.UserOAuthController do
  @moduledoc false
  use RecognizerWeb, :controller

  require Logger

  alias Recognizer.{Accounts, Repo}
  alias RecognizerWeb.Authentication

  plug Ueberauth

  @doc """
  The `callback/2` function handles responses from our Third Party OAuth providers.

  Upon successful authentication we have 2 possible paths for a request:

  1. If it is determined this is the first time we're seeing this user from this provider,
     we need to create a User record and a record for our OAuth credentials.
  2. If the user exists authenticate them
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case get_or_create_user_from_auth(auth) do
      {:ok, user} ->
        Authentication.log_in_user(conn, user)

      {:two_factor, user} ->
        conn
        |> put_session(:two_factor_user_id, user.id)
        |> put_session(:two_factor_sent, false)
        |> redirect(to: Routes.user_two_factor_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, friendly_error_message(changeset))
        |> redirect(to: Routes.user_session_path(conn, :new))

      {:error, e} ->
        {:error, e}
    end
  end

  def callback(%{assigns: %{ueberauth_failure: %{provider: provider}}} = conn, _params) do
    provider =
      provider
      |> to_string()
      |> String.capitalize()

    conn
    |> put_flash(:error, "We were unable to authenticate you with #{provider}.")
    |> redirect(to: Routes.user_session_path(conn, :new))
  end

  defp friendly_error_message(changeset) do
    errors =
      changeset.errors
      |> Enum.map(fn {field, {_text, opts}} -> {field, Keyword.get(opts, :validation)} end)
      |> Enum.into(%{})

    case errors do
      %{email: :unsafe_unique} ->
        "An error occurred. This may indicate you have previously created an account using the email and password combination."

      _ ->
        Logger.error("Unable to create new oauth account - #{inspect(changeset)}")
        "An error occurred. Please contact support."
    end
  end

  defp get_or_create_user_from_auth(auth) do
    provider = to_string(auth.provider)
    uid = to_string(auth.uid)

    user_params =
      auth
      |> provider_params()
      |> Map.put(:newsletter, true)

    with nil <- Accounts.get_user_by_service_guid(provider, uid) do
      register_oauth_user(user_params, provider, uid)
    end
  end

  defp register_oauth_user(user_params, provider, uid) do
    Repo.transaction(fn ->
      with {:ok, user} <- Accounts.register_oauth_user(user_params),
           {:ok, _oauth} <- Accounts.create_oauth(user, provider, uid) do
        user
      else
        {:error, e} ->
          Repo.rollback(e)
      end
    end)
  end

  defp provider_params(%{provider: :google, info: info}) do
    %{
      email: info.email,
      first_name: info.first_name || "Unknown",
      last_name: info.last_name || "User"
    }
  end

  # Github doesn't return `first_name` and `last_name` like other providers,
  # they use `name` which is the full name.
  # We need to make a best guess at dividing it into first and last.
  defp provider_params(%{provider: :github, info: info}) do
    [first_name, last_name] = split_name(info.name)

    %{
      email: info.email,
      first_name: first_name,
      last_name: last_name
    }
  end

  defp split_name(nil), do: ["Unknown", "User"]

  defp split_name(name) when is_binary(name) do
    case String.split(name, " ", parts: 2) do
      [first_name] ->
        # Only one word, use it as first name and provide default last name
        [first_name, "User"]
      [first_name, last_name] ->
        # Two or more words, split into first and rest as last name
        [first_name, last_name]
      [] ->
        # Empty string case
        ["Unknown", "User"]
    end
  end
end

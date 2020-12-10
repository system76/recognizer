defmodule RecognizerWeb.Accounts.OAuthController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.{Accounts, Accounts.User, Repo}
  alias RecognizerWeb.UserAuth

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
      %User{} = user ->
        UserAuth.log_in_user(conn, user)

      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_flash(
          :error,
          "An error occurred. This may indicate you have previously created an account using the email and password combination."
        )
        |> redirect(to: Routes.user_session_path(conn, :new))
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
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp provider_params(%{provider: :google, info: info}) do
    Map.take(info, [:email, :first_name, :last_name])
  end

  # Github doesn't return `first_name` and `last_name` like other providers, 
  # they use `name` which is the full name.
  # We need to make a best guess at dividing it into first and last.
  defp provider_params(%{provider: :github, info: info}) do
    [first_name | rest] = String.split(info.name, " ", size: 2)
    last_name = if rest == [], do: "", else: hd(rest)

    %{
      email: info.email,
      first_name: first_name,
      last_name: last_name
    }
  end
end

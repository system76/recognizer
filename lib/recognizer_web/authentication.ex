defmodule RecognizerWeb.Authentication do
  @moduledoc """
  Helpers for any controller that does user authentication logic.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Guardian.DB, as: GuardianDB
  alias RecognizerWeb.Router.Helpers, as: Routes
  alias Recognizer.Guardian

  @doc """
  Logs the user in.
  """
  def log_in_user(conn, user, params \\ %{}) do
    redirect_opts = login_redirect(conn)

    conn
    |> clear_session()
    |> Guardian.Plug.sign_in(user, params)
    |> redirect(redirect_opts)
  end

  @doc """
  Logs the user in via the API.
  """
  def log_in_api_user(user) do
    {:ok, access_token, _} = Guardian.encode_and_sign(user, token_type: "access")

    {:ok, access_token}
  end

  @doc """
  Logs the user out.
  """
  def log_out_user(conn) do
    redirect_opts = logout_redirect(conn)

    conn
    |> Guardian.Plug.sign_out()
    |> clear_session()
    |> redirect(redirect_opts)
  end

  @doc """
  Revokes all tokens issued to a given resource
  """
  def revoke_all_tokens(resource, claims \\ %{}) do
    {:ok, subject} = Guardian.subject_for_token(resource, claims)

    GuardianDB.revoke_all(subject)
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn) do
    Guardian.Plug.current_resource(conn)
  end

  @doc """
  The URL to redirect the user to after authentication is done.
  """
  def login_redirect(conn) do
    cond do
      get_session(conn, :user_return_to) ->
        [to: get_session(conn, :user_return_to)]

      Application.get_env(:recognizer, :redirect_url) ->
        [external: Application.get_env(:recognizer, :redirect_url)]

      true ->
        [to: Routes.user_settings_path(conn, :edit)]
    end
  end

  @doc """
  The URL to redirect the user to once they are logged out.
  """
  def logout_redirect(conn) do
    cond do
      Map.has_key?(conn.query_params, "redirect_uri") ->
        [external: conn.query_params["redirect_uri"]]

      Application.get_env(:recognizer, :redirect_url) ->
        [external: Application.get_env(:recognizer, :redirect_url)]

      true ->
        [to: Routes.homepage_path(conn, :index)]
    end
  end

  @doc """
  Sets a flash message but only if we are going to stay inside the application.
  If we plan to redirect externally, the function is a noop.
  """
  def conditional_flash(conn, type, message) do
    cond do
      get_session(conn, :user_return_to) -> conn
      Map.has_key?(conn.query_params, "redirect_uri") -> conn
      Application.get_env(:recognizer, :redirect_url) -> conn
      true -> put_flash(conn, type, message)
    end
  end

  @doc """
  Records the current location to be redirected to after
  authentication flow.
  """
  def maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  def maybe_store_return_to(conn), do: conn

  @doc """
  Generate a user's TOTP URL for authenticator apps
  """
  def get_totp_app_url(user) do
    "otpauth://totp/#{user.email}?secret=#{user.two_factor_seed}&issuer=#{two_factor_issuer()}"
  end

  @doc """
  Generate a user's TOTP barcode for authenticator apps
  """
  def generate_totp_barcode(user) do
    user
    |> get_totp_app_url()
    |> EQRCode.encode()
    |> EQRCode.svg(viewbox: true)
  end

  defp two_factor_issuer, do: Application.get_env(:recognizer, :two_factor_issuer)

  @doc """
  Generate a Time Based One Time Password
  """
  def generate_token(%{two_factor_seed: two_factor_seed}), do: generate_token(two_factor_seed)
  def generate_token(two_factor_seed), do: :pot.totp(two_factor_seed, addwindow: 1)

  @doc """
  Validate a user provided token is valid
  """
  def valid_token?(token, %{two_factor_seed: two_factor_seed}), do: valid_token?(token, two_factor_seed)
  def valid_token?(token, two_factor_seed), do: :pot.valid_totp(token, two_factor_seed, window: 1, addwindow: 1)
end

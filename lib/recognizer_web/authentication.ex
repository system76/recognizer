defmodule RecognizerWeb.Authentication do
  @moduledoc """
  Helpers for any controller that does user authentication logic.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias RecognizerWeb.Router.Helpers, as: Routes
  alias Recognizer.Guardian

  @doc """
  Logs the user in.
  """
  def log_in_user(conn, user, params \\ %{}) do
    redirect = return_to(conn)

    conn
    |> clear_session()
    |> Guardian.Plug.sign_in(user, params)
    |> redirect(to: redirect)
  end

  @doc """
  Logs the user out.
  """
  def log_out_user(conn) do
    conn
    |> Guardian.Plug.sign_out()
    |> clear_session()
    |> redirect(to: Routes.homepage_path(conn, :index))
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
  def return_to(conn) do
    get_session(conn, :user_return_to) || Routes.user_settings_path(conn, :edit)
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
  Generate a user's TOTP barcode for authenticator apps
  """
  def generate_totp_barcode(user) do
    "otpauth://totp/#{user.email}?secret=#{user.two_factor_seed}&issuer=#{two_factor_issuer()}"
    |> EQRCode.encode()
    |> EQRCode.svg()
  end

  defp two_factor_issuer, do: Application.get_env(:recognizer, :two_factor_issuer)

  @doc """
  Generate a Time Based One Time Password
  """
  def generate_token(user) do
    :pot.totp(user.two_factor_seed, addwindow: 1)
  end

  @doc """
  Validate a user provided token is valid
  """
  def valid_token?(token, user) do
    :pot.valid_totp(token, user.two_factor_seed, window: 1, addwindow: 1)
  end
end

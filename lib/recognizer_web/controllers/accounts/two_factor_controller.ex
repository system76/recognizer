defmodule RecognizerWeb.Accounts.TwoFactorController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias Recognizer.Accounts.User
  alias Recognizer.Notifications.Account
  alias RecognizerWeb.Authentication

  def new(conn, _params) do
    current_user = get_session(conn, :current_user)

    render_two_factor(conn, current_user)
  end

  def create(conn, params) do
    current_user = get_session(conn, :current_user)
    token = Map.get(params, "token", "")

    if Authentication.valid_token?(token, current_user) do
      Authentication.log_in_user(conn, current_user)
    else
      conn
      |> put_flash(:error, "Invalid two factor code")
      |> render_two_factor(current_user)
    end
  end

  def barcode(conn, _params) do
    barcode =
      conn
      |> Guardian.Plug.current_resource()
      |> barcode_content()
      |> EQRCode.encode()
      |> EQRCode.svg(color: "#574F4A")

    conn
    |> put_resp_content_type("image/svg+xml")
    |> text(barcode)
  end

  defp barcode_content(%{email: email, two_factor_seed: two_factor_seed}) do
    "otpauth://totp/#{email}?secret=#{two_factor_seed}&issuer=#{two_factor_issuer()}"
  end

  defp maybe_send_two_factor_notification(conn, _current_user, :app) do
    conn
  end

  defp maybe_send_two_factor_notification(conn, %User{} = user, _two_factor_method) do
    token = Authentication.generate_token(user)
    Account.deliver_two_factor_token(user, token)

    conn
  end

  defp render_two_factor(conn, current_user) do
    two_factor_method = current_user.notification_preference.two_factor

    conn
    |> maybe_send_two_factor_notification(current_user, two_factor_method)
    |> render("new.html", two_factor_method: two_factor_method)
  end

  defp two_factor_issuer, do: Application.get_env(:recognizer, :two_factor_issuer)
end

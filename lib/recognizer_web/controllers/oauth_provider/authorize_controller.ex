defmodule RecognizerWeb.OauthProvider.AuthorizeController do
  use RecognizerWeb, :controller

  alias ExOauth2Provider.Authorization
  alias RecognizerWeb.Authentication

  def show(conn, %{"code" => code}) do
    render(conn, "show.html", code: code)
  end

  def new(conn, params) do
    user = Authentication.fetch_current_user(conn)

    case Authorization.preauthorize(user, params, otp_app: :recognizer) do
      {:ok, client, scopes} ->
        if client.privileged,
          do: authorize(conn, params),
          else: render(conn, "new.html", params: params, client: client, scopes: scopes)

      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)

      {:native_redirect, %{code: code}} ->
        redirect(conn, to: Routes.oauth_authorize_path(conn, :show, code))

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)
    end
  end

  def create(conn, params) do
    authorize(conn, params)
  end

  def delete(conn, params) do
    conn
    |> Authentication.fetch_current_user()
    |> Authorization.deny(params, otp_app: :recognizer)
    |> redirect_or_render(conn)
  end

  defp authorize(conn, params) do
    conn
    |> Authentication.fetch_current_user()
    |> Authorization.authorize(params, otp_app: :recognizer)
    |> redirect_or_render(conn)
  end

  defp redirect_or_render({:redirect, redirect_uri}, conn) do
    redirect(conn, external: redirect_uri)
  end

  defp redirect_or_render({:native_redirect, payload}, conn) do
    json(conn, payload)
  end

  defp redirect_or_render({:error, error, status}, conn) do
    conn
    |> put_status(status)
    |> json(error)
  end
end

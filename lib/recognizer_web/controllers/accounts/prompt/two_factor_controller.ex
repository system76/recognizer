defmodule RecognizerWeb.Accounts.Prompt.TwoFactorController do
  use RecognizerWeb, :controller

  alias Recognizer.Accounts
  alias RecognizerWeb.Authentication

  plug :ensure_user
  plug :assign_changesets

  def new(conn, _params) do
    render(conn, "edit.html")
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.update_user(conn.assigns.user, user_params) do
      {:ok, updated_user} ->
        preference = get_in(user_params, ["notification_preference", "two_factor"])
        Accounts.generate_and_cache_new_two_factor_settings(updated_user, preference)
        redirect(conn, to: Routes.prompt_two_factor_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def edit(conn, _params) do
    user = conn.assigns.user
    {:ok, %{"two_factor_seed" => seed}} = Accounts.get_new_two_factor_settings(user)

    render(conn, "confirm.html",
      barcode: Authentication.generate_totp_barcode(user, seed),
      totp_app_url: Authentication.get_totp_app_url(user, seed)
    )
  end

  def update(conn, params) do
    user = conn.assigns.user
    two_factor_code = Map.get(params, "two_factor_code", "")

    case Accounts.confirm_and_save_two_factor_settings(two_factor_code, user) do
      {:ok, updated_user} ->
        Authentication.log_in_user(conn, updated_user, params)

      _ ->
        conn
        |> put_flash(:error, "Two factor code is invalid.")
        |> redirect(to: Routes.prompt_two_factor_path(conn, :edit))
    end
  end

  defp ensure_user(conn, _opts) do
    user_id = get_session(conn, :prompt_user_id)

    if user_id == nil do
      RecognizerWeb.FallbackController.call(conn, {:error, :unauthenticated})
    else
      user = Accounts.get_user!(user_id)
      assign(conn, :user, user)
    end
  end

  defp assign_changesets(conn, _opts) do
    conn
    |> assign(:changeset, Accounts.change_user(conn.assigns.user))
    |> assign(:two_factor_changeset, Accounts.change_user_two_factor(conn.assigns.user))
  end
end

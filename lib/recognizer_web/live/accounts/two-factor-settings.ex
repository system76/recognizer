defmodule RecognizerWeb.Accounts.TwoFactorSettingsLive do
  use RecognizerWeb, :live_view

  alias Recognizer.Accounts

  def mount(_params, %{"two_factor_user_id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    changeset = Accounts.change_user_two_factor(user, %{})

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:changeset, changeset)
     |> assign(:params, %{})
     |> assign(:settings, %{})
     |> assign(:step, :choice)}
  end

  def handle_event("choice", %{"user" => user_params}, socket) do
    user = socket.assigns.user

    changeset = Accounts.change_user_two_factor(user, user_params)
    {:ok, settings} = Accounts.get_new_two_factor_settings(user)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:params, user_params)
     |> assign(:settings, settings)
     |> assign(:step, :backup)}
  end

  def handle_event("backup", _params, socket) do
    notification_preferences = Ecto.Changeset.get_field(socket.assigns.changeset, :notification_preference)

    case notification_preferences.two_factor do
      :app ->
        {:noreply, assign(socket, :step, :app_validate)}

      _ ->
        {:noreply, assign(socket, :step, :phone_number)}
    end
  end

  def handle_event("app_validate", %{"user" => %{"two_factor_code" => code}}, socket) do
    user = socket.assigns.user

    with {:ok, semi_updated_user} <- Accounts.confirm_and_save_two_factor_settings(code, user),
         {:ok, updated_user} <- Accounts.update_user(semi_updated_user, socket.assigns.params) do
      {:noreply,
       socket
       |> put_flash(:info, "Two factor authentication enabled.")
       |> push_redirect(to: Routes.user_settings_path(socket, :edit))}
    else
      _ -> {:noreply, put_flash(socket, :error, "Two factor code is invalid.")}
    end
  end

  def handle_event("phone_number", %{"user" => user_attrs}, socket) do
    user = socket.assigns.user
    params = Map.merge(socket.assigns.params, user_attrs)
    changeset = Accounts.change_user_two_factor(user, params)

    if changeset.valid? do
      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> assign(:params, params)
       |> assign(:step, :phone_number_validate)}
    else
      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> assign(:params, params)}
    end
  end

  def handle_event("phone_number_validate", %{"user" => %{"two_factor_code" => code}}, socket) do
    user = socket.assigns.user

    with {:ok, semi_updated_user} <- Accounts.confirm_and_save_two_factor_settings(code, user),
         {:ok, updated_user} <- Accounts.update_user(semi_updated_user, socket.assigns.params) do
      {:noreply,
       socket
       |> put_flash(:info, "Two factor authentication enabled.")
       |> push_redirect(to: Routes.user_settings_path(socket, :edit))}
    else
      _ -> {:noreply, put_flash(socket, :error, "Two factor code is invalid.")}
    end
  end

  def handle_event("resend", _params, socket) do
    %{user: user, settings: settings} = socket.assigns

    Accounts.send_new_two_factor_notification(
      user,
      settings["two_factor_seed"],
      settings["notification_preference"]["two_factor"]
    )

    {:noreply, put_flash(socket, :info, "Two factor code sent.")}
  end

  def render(assigns) do
    template = to_string(assigns.step) <> ".html"
    RecognizerWeb.Accounts.TwoFactorSettingsView.render(template, assigns)
  end
end

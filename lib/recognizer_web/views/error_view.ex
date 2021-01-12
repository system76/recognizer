defmodule RecognizerWeb.ErrorView do
  use RecognizerWeb, :view

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    title = Phoenix.Controller.status_message_from_template(template)

    if String.ends_with?(template, ".json") do
      %{errors: [%{title: title}]}
    else
      title
    end
  end

  def render("error.json", %{changeset: changeset}) do
    reasons =
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Regex.replace(~r"%{(\w+)}", message, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    %{errors: reasons}
  end

  def render("error.json", %{field: field, reason: reason}) do
    %{errors: [%{field => reason}]}
  end
end

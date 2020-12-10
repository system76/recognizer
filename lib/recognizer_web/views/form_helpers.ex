defmodule RecognizerWeb.FormHelpers do
  @moduledoc """
  Conveniences for building forms with Bulma css tags.
  """

  use Phoenix.HTML

  alias RecognizerWeb.ErrorHelpers

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, ErrorHelpers.translate_error(error),
        class: "help is-danger",
        phx_feedback_for: input_id(form, field)
      )
    end)
  end

  @doc """
  Outputs standard bulma classes, and danger classes if any error exists on that
  field.
  """
  def input_classes(form, field) do
    if Enum.empty?(Keyword.get_values(form.errors, field)) do
      "input"
    else
      "input is-danger"
    end
  end
end

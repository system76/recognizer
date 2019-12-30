defmodule Recognizer.FallbackController do
  use RecognizerWeb, :controller

  def call(conn, {:error, :missing_required_fields}) do
    render(conn, "400.json", %{reason: "missing required fields"})
  end
end

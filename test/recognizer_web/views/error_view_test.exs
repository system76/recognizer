defmodule RecognizerWeb.ErrorViewTest do
  use RecognizerWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 400.json" do
    assert render(RecognizerWeb.ErrorView, "400.json", []) ==
             %{errors: %{detail: "Bad Request"}}
  end

  test "renders 401.json" do
    assert render(RecognizerWeb.ErrorView, "401.json", []) ==
             %{errors: %{detail: "Unauthorized"}}
  end

  test "renders 404.json" do
    assert render(RecognizerWeb.ErrorView, "404.json", []) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500.json" do
    assert render(RecognizerWeb.ErrorView, "500.json", []) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

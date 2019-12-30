defmodule Recognizer.AuthView do
  use RecognizerWeb, :view

  def render("login.json", %{access_token: token}) do
  end

  def render("verify.json", _) do
  end
end

defmodule RecognizerWeb.HomepageController do
  use RecognizerWeb, :controller

  def index(conn, _params) do
    if Application.get_env(:recognizer, :redirect_url) do
      redirect(conn, external: Application.get_env(:recognizer, :redirect_url))
    else
      render(conn, "index.html")
    end
  end
end

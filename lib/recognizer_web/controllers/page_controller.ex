defmodule RecognizerWeb.PageController do
  use RecognizerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

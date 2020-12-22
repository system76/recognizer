defmodule RecognizerWeb.Api.ProfileController do
  @moduledoc false
  use RecognizerWeb, :controller

  alias RecognizerWeb.Authentication

  def show(conn, _params) do
    user = Authentication.fetch_current_user(conn)
    render(conn, "show.json", user: user)
  end
end

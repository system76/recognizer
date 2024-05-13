defmodule RecognizerWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use RecognizerWeb, :controller
      use RecognizerWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: RecognizerWeb

      import Plug.Conn
      import RecognizerWeb.Gettext
      import RecognizerWeb.Controllers.Helpers

      alias RecognizerWeb.Router.Helpers, as: Routes

      action_fallback RecognizerWeb.FallbackController
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/recognizer_web/templates",
        namespace: RecognizerWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import RecognizerWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      import Phoenix.View

      import RecognizerWeb.ErrorHelpers
      import RecognizerWeb.FormHelpers
      import RecognizerWeb.Gettext

      use PhoenixHTMLHelpers

      alias RecognizerWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

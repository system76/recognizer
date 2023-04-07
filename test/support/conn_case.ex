defmodule RecognizerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use RecognizerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import RecognizerWeb.ConnCase

      alias RecognizerWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint RecognizerWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Recognizer.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Recognizer.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  setup do
    Redix.command(:redix, ["FLUSHDB"])
    on_exit(fn -> Redix.command(:redix, ["FLUSHDB"]) end)
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_admin(%{conn: conn}) do
    user = Recognizer.AccountFactory.insert(:user)
    Recognizer.AccountFactory.insert(:role, user_id: user.id, role_id: 2)
    %{conn: log_in_user(conn, user), user: user}
  end

  def register_and_log_in_user(%{conn: conn}) do
    user = Recognizer.AccountFactory.insert(:user)
    %{conn: log_in_user(conn, user), user: user}
  end

  def register_and_log_in_oauth_user(%{conn: conn}) do
    user = Recognizer.AccountFactory.insert(:user)
    oauth = Recognizer.AccountFactory.insert(:oauth, user: user)
    user = Recognizer.Accounts.get_user!(user.id)
    %{conn: log_in_user(conn, user), user: user, oauth: oauth}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Recognizer.Guardian.Plug.sign_in(user, %{})
  end
end

defmodule Recognizer.Accounts.VerificationCodeCleanupTask do
  @moduledoc """
  A scheduled task that cleans up old verification codes.
  """

  use GenServer

  import Ecto.Query

  alias Recognizer.Accounts.VerificationCode
  alias Recognizer.Repo

  @interval_in_milliseconds :timer.minutes(17)
  @expiration_time_in_seconds 15 * 60

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_) do
    purge_expired_codes()
    :timer.send_interval(@interval_in_milliseconds, :work)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:work, state) do
    purge_expired_codes()

    {:noreply, state}
  end

  defp purge_expired_codes() do
    Repo.delete_all(expired_codes())
  end

  defp expired_codes() do
    from c in VerificationCode,
      where: c.inserted_at <= ^expiration_time()
  end

  defp expiration_time() do
    NaiveDateTime.add(NaiveDateTime.utc_now(), -@expiration_time_in_seconds, :second)
  end
end

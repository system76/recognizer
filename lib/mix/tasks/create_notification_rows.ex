defmodule Mix.Tasks.CreateNotificationRows do
  use Mix.Task

  alias Ecto.Changeset
  alias Recognizer.Accounts.{NotificationPreference, User}
  alias Recognizer.Repo

  @shortdoc "Creates notification rows for existing users"

  @timestamp NaiveDateTime.local_now()

  def run(_) do
    Mix.Task.run("app.start")

    Repo.transaction(
      fn ->
        User
        |> Repo.stream()
        |> Stream.map(&create_notification_row/1)
        |> Stream.chunk_every(1_000)
        |> Stream.each(&insert_notification_rows/1)
        |> Stream.run()
      end,
      timeout: :infinity
    )
  end

  defp create_notification_row(%{id: user_id}) do
    %NotificationPreference{}
    |> NotificationPreference.changeset(%{user_id: user_id})
    |> Changeset.apply_changes()
    |> Map.from_struct()
    |> Map.drop([:__meta__, :id, :inserted_at, :updated_at, :user])
    |> Map.put(:inserted_at, @timestamp)
    |> Map.put(:updated_at, @timestamp)
  end

  defp insert_notification_rows(rows) do
    Repo.insert_all(NotificationPreference, rows, on_conflict: :replace_all)
  end
end

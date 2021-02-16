{:ok, _} = Application.ensure_all_started(:ex_machina)

if System.get_env("CI") == "true" do
  Code.put_compiler_option(:warnings_as_errors, true)
end

Ecto.Adapters.SQL.Sandbox.mode(Recognizer.Repo, :manual)

ExUnit.start()

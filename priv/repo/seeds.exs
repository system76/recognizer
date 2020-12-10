# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Recognizer.Repo.insert!(%Recognizer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Recognizer.Repo.insert!(%Recognizer.Accounts.User{
  id: 1,
  first_name: "Test",
  last_name: "Account",
  username: "test-at-example768c07eb5dab28aed",
  email: "test@example.com",
  hashed_password: Argon2.hash_pwd_salt("System76")
})

Recognizer.Repo.insert!(%Recognizer.OauthProvider.Application{
  name: "Privileged Application",
  uid: "1",
  redirect_uri: "https://localhost:3000",
  privileged: true,
  owner_id: 1
})

Recognizer.Repo.insert!(%Recognizer.OauthProvider.Application{
  name: "Third Party Application",
  uid: "2",
  redirect_uri: "https://localhost:3000",
  owner_id: 1
})

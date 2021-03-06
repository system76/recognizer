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

Recognizer.Repo.insert!(%Recognizer.Accounts.Role{
  role_id: 1,
  user_id: 1
})

Recognizer.Repo.insert!(%Recognizer.Accounts.NotificationPreference{
  user_id: 1
})

Recognizer.Repo.insert!(%Recognizer.Accounts.Organization{
  id: 1,
  name: "Strict Organization",
  password_reuse: 4,
  password_expiration: 1,
  two_factor_app_required: true
})

Recognizer.Repo.insert!(%Recognizer.Accounts.User{
  id: 2,
  first_name: "Company",
  last_name: "Person",
  username: "test-at-example768c07eb5dab28aed",
  email: "company@example.com",
  hashed_password: Argon2.hash_pwd_salt("System76"),
  password_changed_at: ~N[2021-01-01 01:01:01],
  organization_id: 1
})

Recognizer.Repo.insert!(%Recognizer.Accounts.Role{
  role_id: 1,
  user_id: 2
})

Recognizer.Repo.insert!(%Recognizer.Accounts.NotificationPreference{
  user_id: 2
})

Recognizer.Repo.insert!(%Recognizer.OauthProvider.Application{
  name: "Privileged Application",
  uid: "privileged",
  redirect_uri: "http://localhost:3002/auth/callback http://localhost:3000/auth/callback",
  privileged: true,
  owner_id: 1
})

Recognizer.Repo.insert!(%Recognizer.OauthProvider.Application{
  name: "Third Party Application",
  uid: "third-party",
  redirect_uri: "http://localhost:3002/auth/callback http://localhost:3000/auth/callback",
  owner_id: 1
})

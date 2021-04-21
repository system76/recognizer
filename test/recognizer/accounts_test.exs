defmodule Recognizer.AccountsTest do
  use Recognizer.DataCase

  import Mox
  import Recognizer.AccountFactory

  alias Recognizer.Accounts
  alias Recognizer.Accounts.User

  @new_valid_password "NeWVal1DP!ssW0R$"

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = insert(:user)
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = insert(:user)
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      password = build(:password)
      %{id: id} = user = insert(:user, password: password)
      assert {:ok, %User{id: ^id}} = Accounts.get_user_by_email_and_password(user.email, password)
    end

    test "returns the {:two_factor, user} if the email and password are valid with two factor enabled" do
      password = build(:password)
      %{id: id} = user = :user |> build(password: password) |> add_two_factor() |> insert()
      assert {:two_factor, %User{id: ^id}} = Accounts.get_user_by_email_and_password(user.email, password)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(123)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = insert(:user)
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["must contain an UPPERCASE letter", "must contain a number"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      user_params = :user |> insert() |> Map.take([:first_name, :last_name, :email])
      {:error, changeset} = Accounts.register_user(user_params)
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{user_params | email: String.upcase(user_params.email)})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      {:ok, user} = 
        :user
        |> params_for(%{email: "TEST@Example.com"})
        |> Accounts.register_user()

      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
      assert "test@example.com" == user.email
    end

    test "adds login role" do
      {:ok, user} = Accounts.register_user(params_for(:user))
      assert Enum.any?(user.roles, fn r -> r.role_id == 1 end)
    end
  end

  describe "user_prompts/1" do
    test "returns the {:password_change, user} if password has expired with a policy" do
      %{id: id} =
        user =
        :user
        |> build(password_changed_at: ~N[2020-01-01 01:01:01])
        |> add_organization_policy(password_expiration: 1)
        |> insert()

      assert {:password_change, %User{id: ^id}} = Accounts.user_prompts(user)
    end

    test "returns the {:two_factor, user} if 2FA is not enabled and is in the policy" do
      %{id: id} =
        user =
        :user
        |> build()
        |> add_organization_policy(two_factor_app_required: true)
        |> insert()

      assert {:two_factor, %User{id: ^id}} = Accounts.user_prompts(user)
    end

    test "returns the {:two_factor, user} if 2FA is enabled to non app method" do
      %{id: id} =
        user =
        :user
        |> build()
        |> add_two_factor(:text)
        |> add_organization_policy(two_factor_app_required: true)
        |> insert()

      assert {:two_factor, %User{id: ^id}} = Accounts.user_prompts(user)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email, :first_name, :last_name, :type]
    end

    test "allows fields to be set" do
      params = params_for(:user)
      changeset = Accounts.change_user_registration(%User{}, params)

      assert changeset.valid?
      assert get_change(changeset, :first_name) == params.first_name
      assert get_change(changeset, :last_name) == params.last_name
      assert get_change(changeset, :email) == params.email
      assert get_change(changeset, :password) == params.password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user(%User{})
      assert changeset.required == [:email, :first_name, :last_name, :type]
    end
  end

  describe "update_user/2" do
    setup :verify_on_exit!

    setup do
      %{user: insert(:user)}
    end

    test "updates the email", %{user: user} do
      assert {:ok, _user} = Accounts.update_user(user, %{email: "TEST@Example.com"})
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert "test@example.com" == changed_user.email
    end

    test "clears company name for individual accounts", %{user: user} do
      assert {:ok, _user} = Accounts.update_user(user, %{type: :individual, company_name: "test"})
      changed_user = Repo.get!(User, user.id)
      assert changed_user.type == :individual
      assert changed_user.company_name == ""
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      password = build(:password)
      changeset = Accounts.change_user_password(%User{}, %{"password" => password})

      assert changeset.valid?
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: insert(:user)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, build(:password), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["must contain an UPPERCASE letter", "must contain a number"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.update_user_password(user, build(:password), %{password: too_long})

      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates password is not the same as current", %{user: user} do
      updatable_user = Accounts.get_user!(user.id)
      {:error, changeset} = Accounts.update_user_password(updatable_user, user.password, %{password: user.password})
      assert "must be a new password" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.update_user_password(user, "invalid", %{password: build(:password)})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, user.password, %{
          password: @new_valid_password
        })

      assert Accounts.get_user_by_email_and_password(user.email, @new_valid_password)
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = insert(:user)
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = insert(:user)
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: insert(:user)}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token_user, _claims} = Recognizer.Guardian.resource_from_token(token, %{"typ" => "reset_password"})

      assert token_user.id == user.id
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = insert(:user)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
    end

    test "does not return the user with invalid token" do
      refute Accounts.get_user_by_reset_password_token("oops")
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: insert(:user)}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["must contain an UPPERCASE letter", "must contain a number"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, _updated_user} =
        Accounts.reset_user_password(user, %{password: @new_valid_password, password_confirmation: @new_valid_password})

      assert {:ok, Accounts.get_user_by_email_and_password(user.email, @new_valid_password)}
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.reset_user_password(user, %{password: @new_valid_password, password_confirmation: @new_valid_password})
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end

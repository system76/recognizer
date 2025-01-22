defmodule Recognizer.Accounts do
  @moduledoc """
  The Accounts context.
  """

  require Logger

  import Ecto.Query, warn: false

  alias Recognizer.Accounts.OAuth
  alias Recognizer.Accounts.RecoveryCode
  alias Recognizer.Accounts.User
  alias Recognizer.Accounts.VerificationCode
  alias Recognizer.BigCommerce
  alias Recognizer.Notifications.Account, as: Notification
  alias Recognizer.Guardian
  alias Recognizer.Repo
  alias RecognizerWeb.Authentication

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    query =
      from u in User,
        join: n in assoc(u, :notification_preference),
        left_join: o in assoc(u, :organization),
        where: u.email == ^email,
        preload: [notification_preference: n, roles: [], organization: o]

    Repo.one(query)
  end

  @doc """
  Gets a user by a third party service login.

  ## Examples

      iex> get_user_by_service_guid("github", "1234")
      %User{}

      iex> get_user_by_service_guid("github", "nope")
      nil

  """
  def get_user_by_service_guid(service, service_guid) do
    query =
      from o in OAuth,
        join: u in assoc(o, :user),
        join: n in assoc(u, :notification_preference),
        left_join: org in assoc(u, :organization),
        where: o.service == ^service and o.service_guid == ^service_guid,
        preload: [user: {u, [notification_preference: n, roles: [], organization: org]}]

    with %OAuth{user: user} <- Repo.one(query),
         %User{two_factor_enabled: false} <- user do
      {:ok, %{user | third_party_login: true}}
    else
      %User{two_factor_enabled: true} = user ->
        {:two_factor, %{user | third_party_login: true}}

      _ ->
        nil
    end
  end

  @doc """
  Creates a new third party service login for a user.
  """
  def create_oauth(user, service, service_guid) do
    attrs = %{service: service, service_guid: service_guid, user_id: user.id}

    %OAuth{}
    |> OAuth.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      {:ok, %User{}}

      iex> get_user_by_email_and_password("foo@example.com", "two_factor_enabled")
      {:two_factor, %User{}}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    query =
      from u in User,
        join: n in assoc(u, :notification_preference),
        left_join: o in assoc(u, :organization),
        left_join: uo in assoc(u, :oauths),
        where: u.email == ^email,
        preload: [oauths: uo, notification_preference: n, roles: [], organization: o]

    with %User{} = user <- Repo.one(query),
         %User{third_party_login: false} <- User.load_virtuals(user),
         true <- User.valid_password?(user, password),
         %User{two_factor_enabled: false} <- user do
      {:ok, user}
    else
      %User{third_party_login: true} = user ->
        {:oauth, user}

      %User{two_factor_enabled: true} = user ->
        {:two_factor, user}

      _ ->
        nil
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    query =
      from u in User,
        join: n in assoc(u, :notification_preference),
        left_join: o in assoc(u, :organization),
        left_join: uo in assoc(u, :oauths),
        where: u.id == ^id,
        preload: [oauths: uo, notification_preference: n, roles: [], organization: o]

    query |> Repo.one!() |> User.load_virtuals()
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs, opts \\ []) do
    Repo.transaction(fn ->
      case do_register_user(attrs, opts) do
        {:ok, user} -> user
        {:error, e} -> Repo.rollback(e)
      end
    end)
  end

  defp do_register_user(attrs, verify_account_url_fun: verify_account_url_fun) do
    %User{}
    |> User.registration_changeset(attrs)
    |> insert_user_and_notification_preferences()
    |> maybe_create_big_commerce_customer()
    |> maybe_generate_verification_code(verify_account_url_fun)
    |> maybe_send_newsletter(attrs)
  end

  defp do_register_user(attrs, opts) do
    %User{}
    |> User.registration_changeset(attrs, opts)
    |> insert_user_and_notification_preferences()
    |> maybe_create_big_commerce_customer()
    |> maybe_mark_user_verified()
    |> maybe_notify_new_user()
    |> maybe_send_newsletter(attrs)
  end

  @doc """
  Registers a user from a third party service. This is different from above
  because it does not set a password, therefor only letting the user login with
  their third party account.
  """
  def register_oauth_user(attrs) do
    %User{}
    |> User.oauth_registration_changeset(attrs)
    |> insert_user_and_notification_preferences()
    |> maybe_create_big_commerce_customer()
    |> maybe_notify_new_user()
  end

  defp insert_user_and_notification_preferences(changeset) do
    with {:ok, user} <- Repo.insert(changeset) do
      user
      |> Ecto.build_assoc(:notification_preference)
      |> Repo.insert()

      {:ok, user}
    end
  end

  def maybe_create_big_commerce_customer({:ok, user}) do
    if BigCommerce.enabled?() do
      BigCommerce.get_or_create_customer(user)
    else
      {:ok, user}
    end
  end

  def maybe_create_big_commerce_customer(error) do
    error
  end

  defp maybe_notify_new_user({:ok, user}) do
    {:ok, _} = Notification.deliver_user_created_message(user)
    {:ok, user}
  end

  defp maybe_notify_new_user(error) do
    error
  end

  defp maybe_send_newsletter({:ok, _user} = response, %{"newsletter" => "true"} = attrs) do
    Recognizer.Hal.update_newsletter(attrs)
    response
  end

  defp maybe_send_newsletter(response, _attrs) do
    response
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user's basic profile settings.

  ## Examples

      iex> change_user(user, %{email: "new@example.com"})
      %User{}

  """
  def change_user(user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Updates the user's basic profile settings. This does not touch more advanced
  things like notification preferences, or password.

  ## Examples

      iex> update_user(user, %{email: "valid@example.com"})
      {:ok, %User{}}

      iex> update_user(user, %{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(user, attrs) do
    if Map.has_key?(attrs, "newsletter"), do: Recognizer.Hal.update_newsletter(attrs)
    changeset = User.changeset(user, attrs)

    with {:ok, updated_user} <- Repo.update(changeset),
         {:ok, _} <- maybe_update_big_commerce_customer(updated_user) do
      Notification.deliver_user_updated_message(updated_user)

      {:ok, updated_user}
    end
  end

  defp maybe_update_big_commerce_customer(user) do
    if BigCommerce.enabled?() do
      Recognizer.BigCommerce.update_customer(user)
    else
      {:ok, user}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:oauth, user_and_oauth_access_query(user))
    |> Ecto.Multi.delete_all(:tokens, user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, _} = Notification.deliver_user_password_changed_notification(user)
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end

  ## Prompts / Organization

  @doc """
  Checks if we need to prompt the user with anything between logins. This could
  be an organization security requirement, like needing to enable two factor,
  or requiring a password reset.

  ## Examples

      iex> user_prompts(user)
      {:ok, %User{}}

      iex> user_prompts(old_password_user)
      {:password_change, %User{}}

      iex> user_prompts(two_factorless_user)
      {:two_factor, %User{}}

  """
  def user_prompts(%{verified_at: nil} = user) do
    {:verification_required, user}
  end

  def user_prompts(%{organization_id: nil} = user) do
    {:ok, user}
  end

  def user_prompts(%{organization: %Ecto.Association.NotLoaded{}} = user) do
    user |> Repo.preload(:organization) |> user_prompts()
  end

  def user_prompts(%{organization: org} = user) do
    fields = Map.from_struct(org)

    with nil <- Enum.find_value(fields, &user_prompts(&1, user)) do
      {:ok, user}
    end
  end

  defp user_prompts({_policy, nil}, _user) do
    false
  end

  defp user_prompts({:password_expiration, days}, user) do
    password_date = NaiveDateTime.add(user.password_changed_at, days * 86_400, :second)

    case NaiveDateTime.compare(password_date, NaiveDateTime.utc_now()) do
      :lt -> {:password_change, user}
      _ -> false
    end
  end

  defp user_prompts({:two_factor_app_required, true}, user) do
    two_factor_enabled? = user.two_factor_enabled
    two_factor_method = user.notification_preference.two_factor

    if not two_factor_enabled? or two_factor_method !== :app do
      {:two_factor, user}
    else
      false
    end
  end

  defp user_prompts(_, _user) do
    false
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    with {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      token
    end
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    case Guardian.resource_from_token(token, %{"typ" => "access"}) do
      {:ok, user, _claims} -> user
      _ -> nil
    end
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    with {:ok, _claims} <- Guardian.revoke(token) do
      :ok
    end
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{"typ" => "reset_password"})

    Notification.deliver_reset_password_instructions(
      user,
      reset_password_url_fun.(token)
    )
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    case Guardian.resource_from_token(token, %{"typ" => "reset_password"}) do
      {:ok, user, _claims} -> user
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:oauth, user_and_oauth_access_query(user))
    |> Ecto.Multi.delete_all(:tokens, user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  defp user_and_contexts_query(user, :all) do
    {:ok, sub} = Guardian.subject_for_token(user, %{})

    from t in "users_tokens",
      where: t.sub == ^sub
  end

  defp user_and_contexts_query(user, typ) do
    {:ok, sub} = Guardian.subject_for_token(user, %{"typ" => typ})

    from t in "users_tokens",
      where: t.sub == ^sub and t.typ == ^typ
  end

  defp user_and_oauth_access_query(user) do
    from at in Recognizer.OauthProvider.AccessToken,
      where: at.resource_owner_id == ^user.id
  end

  def change_user_two_factor(user, attrs \\ %{}) do
    User.two_factor_changeset(user, attrs)
  end

  def generate_new_recovery_codes(user) do
    12
    |> RecoveryCode.generate_codes()
    |> Enum.into([], &%{code: &1, user_id: user.id})
  end

  def generate_new_two_factor_seed do
    5
    |> :crypto.strong_rand_bytes()
    |> Base.encode32()
  end

  @doc """
  Updates the user's two factor status and preference.

  ## Examples

  iex> update_user_two_factor(user, %{"two_factor_enabled" => true, "notification_preference" => %{"two_factor" => "app"}})
      {:ok, %User{}}

  """
  def update_user_two_factor(user, attrs) do
    user_changeset = change_user_two_factor(user, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, user_changeset)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, :user, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Use a recovery code to recover an account. Doing so also consumes the code.
  """
  def recover_account(user, recovery_code) do
    user = %{recovery_codes: codes} = Repo.preload(user, [:notification_preference, :recovery_codes])

    case Enum.split_with(codes, &(&1.code == recovery_code)) do
      {[], _remaining_codes} ->
        :error

      {[%{code: consumed_code}], remaining_codes} ->
        Notification.deliver_user_recovery_code_used_notification(user, consumed_code, remaining_codes)

        user
        |> User.recovery_codes_changeset(remaining_codes)
        |> Repo.update()
    end
  end

  @doc """
  To support the flow we've been provided we need to store configuration options and recovery codes
  before we persist them so the user can be required to download the codes and confirm the method.

  This function caches the user's choices and sends a code if they're using voice or text.
  """
  def generate_and_cache_new_two_factor_settings(user, preference) do
    new_seed = generate_new_two_factor_seed()

    attrs = %{
      notification_preference: %{two_factor: preference},
      recovery_codes: generate_new_recovery_codes(user),
      two_factor_seed: new_seed,
      two_factor_enabled: true
    }

    :ok =
      Redix.noreply_command(:redix, [
        "SET",
        "two_factor_settings:#{user.id}",
        Jason.encode!(attrs),
        "EX",
        config(:cache_expiry)
      ])

    attrs
  end

  def update_two_factor_issue_time(user, attrs, issue_time) do
    %{
      notification_preference: %{two_factor: preference},
      two_factor_seed: seed
    } = attrs


    updated_attrs = %{
      notification_preference: %{two_factor: preference},
      recovery_codes: generate_new_recovery_codes(user),
      two_factor_seed: seed,
      two_factor_enabled: true,
      two_factor_issue_time: issue_time
    }

    :ok =
      Redix.noreply_command(:redix, [
        "SET",
        "two_factor_settings:#{user.id}",
        Jason.encode!(updated_attrs),
        "EX",
        config(:cache_expiry),
        "XX"
    ])

    attrs
  end




  @doc """
  Sends a new notification message to the user to verify their _new_ two factor
  settings.
  """
  def send_new_two_factor_notification(user) do
    {:ok, attrs} = get_new_two_factor_settings(user)
    send_new_two_factor_notification(user, attrs)
  end

  # 토큰 발송 로직을 별도 함수로 분리해 중복 제거
  defp deliver_two_factor_token(user, seed, preference, two_factor_issue_time) do
    IO.inspect("deliver_two_factor_token", label: "deliver_two_factor_token")
    token = Authentication.generate_token(preference, two_factor_issue_time, seed)
    Notification.deliver_two_factor_token(user, token, String.to_existing_atom(preference))
  end

  def send_new_two_factor_notification(user, attrs) do
    # attrs에서 preference와 seed 추출
    %{
      notification_preference: %{two_factor: preference},
      two_factor_seed: seed
    } = attrs

    IO.inspect("send_new_two_factor_notification", label: "send_new_two_factor_notification")

    # preference가 "app"이 아닐 때만 처리
    if preference != "app" do
      # 현재 시각(초 단위)
      current_time = System.system_time(:second)

      # Redis에서 기존 2FA 설정 조회
      redis_result = get_new_two_factor_settings(user)
      # 이 변수를 통해 최종적으로 two_factor_issue_time에 어떤 값을 넣을지 결정
      new_issue_time =
        case redis_result do
          # 1) Redis에 설정이 없음
          {:ok, nil} ->
            {:error, "No settings found for user #{user.id}"}

          # 2) Redis에서 JSON 맵을 정상적으로 읽어옴
          {:ok, settings} when is_map(settings) ->
            IO.inspect(settings, label: "settings")

            if Map.has_key?(settings, :two_factor_issue_time) do
              # 기존 발급 시간 존재
              last_issue_time = settings.two_factor_issue_time
              # 로직상: 현재 시각 - 기존 발급 시각 > 60초 => 즉, 1분 이상이면 토큰을 재발송
              IO.inspect(current_time - current_time, label: "time diff")
              if current_time - last_issue_time > 60 do
                IO.inspect("true", label: "true true")  # 실제론 '너무 이르다'일 수도 있음
                deliver_two_factor_token(user, seed, preference, current_time)
                {:ok, current_time}
              else
                IO.inspect("true", label: "true false")
                # 여기서는 별도 토큰 발송 없이 기존 시간만 유지
                {:ok, last_issue_time}
              end

            else
              # 기존 발급 시간이 없으면(키 자체는 있지만 필드 누락)
              IO.inspect("false", label: "false")
              # 새로 토큰 발급
              deliver_two_factor_token(user, seed, preference, current_time)
              # 이번 발급 시각을 기록
              {:ok, current_time}
            end

          # 3) Redis 에러 또는 예기치 않은 값
          {:error, reason} ->
            {:error, "Failed to fetch or decode settings: #{inspect(reason)}"}

          other ->
            {:error, "Unexpected result: #{inspect(other)}"}
        end

      # 위 case 결과에 따라 Redis에 다시 저장
      case new_issue_time do

        {:ok, issue_time} ->
          update_two_factor_issue_time(user, attrs, issue_time)

        {:error, msg} ->
          IO.inspect(msg, label: "Error or No Settings")
          # 필요 시 추가 처리 가능 (return, 로그 등)

          IO.inspect("No operation performed", label: "No Update")
      end
    end

    :ok
  end

  @doc """
  Retrieves the new user's two factor settings from our cache. These settings
  are not yet active, but are in the process of being verified.
  """
  def get_new_two_factor_settings(user) do
    case Redix.command(:redix, ["GET", "two_factor_settings:#{user.id}"]) do
      {:ok, nil} -> {:ok, nil}
      {:ok, settings} -> Jason.decode(settings, keys: :atoms!)
      res -> res
    end
  end

  @doc """
  Confirms the user's two factor settings and persists them to the database from our cache
  """


  def confirm_and_save_two_factor_settings(code, counter, user) do
    IO.inspect(code, label: "code")
    IO.inspect(counter, label: "counter")
    IO.inspect(user, label: "user")


    with {:ok, %{ notification_preference: %{two_factor: preference},
    two_factor_seed: seed} = attrs} <- get_new_two_factor_settings(user),
    true <- Authentication.valid_token?(preference, code, counter, seed) do

      user
      |> Repo.preload([:notification_preference, :recovery_codes])
      |> User.two_factor_changeset(attrs)
      |> Repo.update()
      else
      _ -> :error
    end
  end

  @doc """
  Deletes cached settings.
  """
  def clear_two_factor_settings(user), do: {:ok, _} = Redix.command(:redix, ["DEL", "two_factor_settings:#{user.id}"])

  def load_notification_preferences(user) do
    Repo.preload(user, :notification_preference)
  end

  ## Account Verification

  def get_user_by_verification_code(code) do
    case Repo.get_by(VerificationCode, code: code) do
      nil -> {:error, :code_not_found}
      verification_code -> {:ok, Repo.get(User, verification_code.user_id)}
    end
  end

  def resend_verification_code(user, verify_account_url_fun) do
    case Repo.get_by(VerificationCode, user_id: user.id) do
      nil ->
        maybe_generate_verification_code({:ok, user}, verify_account_url_fun)

      verification ->
        Notification.deliver_account_verification_instructions(user, verify_account_url_fun.(verification.code))
    end
  end

  def verify_user(code) do
    case get_user_by_verification_code(code) do
      {:ok, user} ->
        mark_user_verified(user)

      error ->
        error
    end
  end

  defp maybe_mark_user_verified({:ok, user}) do
    mark_user_verified(user)
  end

  defp maybe_mark_user_verified(error) do
    error
  end

  defp mark_user_verified(user) do
    {:ok, verified_user} =
      user
      |> User.verification_changeset(%{verified_at: Repo.now()})
      |> Repo.update()

    delete_verification_codes_for_user(verified_user)
    {:ok, verified_user}
  end

  defp maybe_generate_verification_code({:ok, user}, verify_account_url_fun) do
    {:ok, verification} =
      %VerificationCode{}
      |> VerificationCode.changeset(%{code: VerificationCode.generate_code(), user_id: user.id})
      |> Repo.insert()

    Notification.deliver_account_verification_instructions(user, verify_account_url_fun.(verification.code))

    {:ok, user}
  end

  defp maybe_generate_verification_code(error, _verify_account_url_fun) do
    error
  end

  defp delete_verification_codes_for_user(%{id: user_id}) do
    user_codes =
      from c in VerificationCode,
        where: c.user_id == ^user_id

    Repo.delete_all(user_codes)
  end

  defp config(key), do: Application.get_env(:recognizer, __MODULE__)[key]
end

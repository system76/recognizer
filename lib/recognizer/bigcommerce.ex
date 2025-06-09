defmodule Recognizer.BigCommerce do
  @moduledoc """
  BigCommerce context.
  """

  require Logger

  alias Recognizer.Accounts.BCCustomerUser, as: Customer
  alias Recognizer.BigCommerce.Client
  alias Recognizer.BigCommerce.Token
  alias Recognizer.Repo

  def enabled?() do
    config(:enabled?)
  end

  def create_customer(user) do
    case Client.create_customer(user) do
      {:ok, bc_id} ->
        Repo.insert(%Customer{user_id: user.id, bc_id: bc_id})
        {:ok, user}

      {:error, e} ->
        Logger.error("error creating bigcommerce customer: #{inspect(e)}")
        {:error, e}
    end
  end

  def get_or_create_customer(%{email: email, id: id} = user) do
    Logger.info("Starting BigCommerce get_or_create_customer for user #{id} with email #{email}")

    case Client.get_customers(emails: [email]) do
      {:ok, []} ->
        Logger.info("No existing BigCommerce customer found for email #{email}, creating new customer")
        result = create_customer(user)
        Logger.info("BigCommerce customer creation result: #{inspect(result)}")
        result

      {:ok, [customer_id]} ->
        Logger.info("Found existing BigCommerce customer #{customer_id} for email #{email}")

        case Repo.insert(%Customer{user_id: id, bc_id: customer_id}) do
          {:ok, _customer_db_entry} ->
            Logger.info("Successfully linked BigCommerce customer #{customer_id} to user #{id}")
            {:ok, user}

          {:error, changeset} ->
            Logger.error("Error inserting BigCommerce customer into local DB: #{inspect(changeset)}")
            # Return success anyway since the BigCommerce customer exists
            # This helps with the case where a user tries to create an account twice
            Logger.info("Returning success despite DB error since BigCommerce customer exists")
            {:ok, user}
        end

      {:error, e} ->
        Logger.error("Error while getting BigCommerce customer: #{inspect(e)}")
        # Don't fail account creation due to BigCommerce API errors
        # This ensures verification emails are still sent
        Logger.info("Continuing account creation process despite BigCommerce error")
        {:ok, user}

      e ->
        Logger.error("Unexpected error while getting or creating BigCommerce customer: #{inspect(e)}")
        # Don't fail account creation due to BigCommerce errors
        # This ensures verification emails are still sent
        Logger.info("Continuing account creation process despite unexpected BigCommerce error")
        {:ok, user}
    end
  end

  def get_or_create_customer(e) do
    Logger.error("unexpected customer #{inspect(e)}")
    {:error, "unexpected customer"}
  end

  def update_customer(user) do
    case Client.update_customer(Repo.preload(user, :bigcommerce_user)) do
      {:ok, _} ->
        {:ok, user}

      {:error, e} ->
        Logger.error("error creating bigcommerce customer: #{inspect(e)}")
        {:error, e}
    end
  end

  def home_redirect_uri(), do: config(:store_home_uri)

  def login_redirect_uri(user) do
    user = ensure_bigcommerce_user(user)

    case generate_login_jwt(user) do
      {:error, _reason} ->
        # BigCommerce 연결이 없는 경우 기본 홈 URI로 리디렉션
        home_redirect_uri()

      token ->
        home_redirect_uri() <> config(:login_path) <> token
    end
  end

  def checkout_redirect_uri(user) do
    user = ensure_bigcommerce_user(user)

    case generate_checkout_login_jwt(user) do
      {:error, _reason} ->
        # BigCommerce 연결이 없는 경우 기본 홈 URI로 리디렉션
        home_redirect_uri()

      token ->
        home_redirect_uri() <> config(:login_path) <> token
    end
  end

  def logout_redirect_uri(), do: home_redirect_uri() <> config(:logout_path)

  defp generate_checkout_login_jwt(user) do
    user = Recognizer.Repo.preload(user, :bigcommerce_user)

    case jwt_claims(user) do
      {:error, reason} ->
        {:error, reason}

      claims ->
        case claims
             |> Map.put("redirect_to", "/checkout")
             |> Token.generate_and_sign(jwt_signer()) do
          {:ok, token, _claims} -> token
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp generate_login_jwt(user) do
    user = Recognizer.Repo.preload(user, :bigcommerce_user)

    case jwt_claims(user) do
      {:error, reason} ->
        {:error, reason}

      claims ->
        case claims
             |> Map.put("redirect_to", "/")
             |> Token.generate_and_sign(jwt_signer()) do
          {:ok, token, _claims} -> token
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp jwt_claims(user) do
    if user.bigcommerce_user do
      %{
        "aud" => "BigCommerce",
        "iss" => config(:client_id),
        "jti" => Ecto.UUID.generate(),
        "operation" => "customer_login",
        "store_hash" => config(:store_hash),
        "customer_id" => user.bigcommerce_user.bc_id
      }
    else
      {:error, "BigCommerce user not found"}
    end
  end

  defp jwt_signer() do
    Joken.Signer.create("HS256", config(:client_secret))
  end

  defp config(key) do
    Application.get_env(:recognizer, __MODULE__)[key]
  end

  # BigCommerce 사용자가 없으면 생성하고, 있으면 그대로 반환
  defp ensure_bigcommerce_user(user) do
    user = Recognizer.Repo.preload(user, :bigcommerce_user)

    if user.bigcommerce_user do
      user
    else
      # BigCommerce 계정이 없으면 생성 시도
      case get_or_create_customer(user) do
        {:ok, _user} ->
          # 다시 preload해서 최신 상태로 가져오기
          Recognizer.Repo.preload(user, :bigcommerce_user, force: true)

        {:error, _reason} ->
          # 생성 실패 시 원본 사용자 반환 (bigcommerce_user는 nil)
          user
      end
    end
  end
end

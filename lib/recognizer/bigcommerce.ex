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
      {:ok, :email_already_exists} ->
        handle_email_already_exists(user)

      {:ok, bc_id} when is_integer(bc_id) ->
        handle_new_customer_created(user, bc_id)

      {:error, e} ->
        handle_customer_creation_error(user, e)
    end
  end

  defp handle_email_already_exists(user) do
    Logger.info("BigCommerce customer email already exists for user #{user.id}, attempting to link existing customer")

    case Client.get_customers(emails: [user.email]) do
      {:ok, [customer_id | _]} ->
        link_existing_customer(user, customer_id)

      {:ok, []} ->
        handle_customer_not_found_error(user)

      {:error, e} ->
        handle_get_customers_error(user, e)
    end
  end

  defp link_existing_customer(user, customer_id) do
    case Repo.insert(%Customer{user_id: user.id, bc_id: customer_id}) do
      {:ok, _} ->
        Logger.info("Successfully linked existing BigCommerce customer #{customer_id} to user #{user.id}")
        {:ok, user}

      {:error, changeset} ->
        Logger.error("Failed to link BigCommerce customer to user: #{inspect(changeset)}")
        {:error, {:bigcommerce_link_failed, changeset}}
    end
  end

  defp handle_customer_not_found_error(user) do
    Logger.error("BigCommerce reported email exists but customer not found via API for user #{user.id}")
    {:error, {:bigcommerce_customer_not_found, "Email exists but customer not found"}}
  end

  defp handle_get_customers_error(user, e) do
    Logger.error("Failed to get existing BigCommerce customer for user #{user.id}: #{inspect(e)}")
    {:error, {:bigcommerce_api_error, e}}
  end

  defp handle_new_customer_created(user, bc_id) do
    case Repo.insert(%Customer{user_id: user.id, bc_id: bc_id}) do
      {:ok, _} ->
        {:ok, user}

      {:error, changeset} ->
        Logger.error("Failed to save BigCommerce customer ID to database: #{inspect(changeset)}")
        {:ok, user}
    end
  end

  defp handle_customer_creation_error(user, e) do
    Logger.error("BigCommerce customer creation failed for user #{user.id}: #{inspect(e)}")
    {:error, e}
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
        # Apply strict approach: fail account creation for BigCommerce API errors
        {:error, e}

      e ->
        Logger.error("Unexpected error while getting or creating BigCommerce customer: #{inspect(e)}")
        # Apply strict approach: fail account creation for unexpected errors
        {:error, "Unexpected BigCommerce error"}
    end
  end

  def get_or_create_customer(e) do
    Logger.error("unexpected customer #{inspect(e)}")
    {:error, "unexpected customer"}
  end

  def update_customer(user) do
    case Client.update_customer(Repo.preload(user, :bigcommerce_user)) do
      {:ok, :email_already_exists} ->
        # When updating, email already exists is actually a success condition
        Logger.info("BigCommerce customer update: email already exists for user #{user.id}, treating as success")
        {:ok, user}

      {:ok, _} ->
        {:ok, user}

      {:error, e} ->
        Logger.error("BigCommerce customer update failed: #{inspect(e)}")
        {:error, e}
    end
  end

  def home_redirect_uri(), do: config(:store_home_uri)

  def login_redirect_uri(user) do
    user = ensure_bigcommerce_user(user)

    case generate_login_jwt(user) do
      {:error, _reason} ->
        home_redirect_uri()

      token ->
        home_redirect_uri() <> config(:login_path) <> token
    end
  end

  def checkout_redirect_uri(user) do
    user = ensure_bigcommerce_user(user)

    case generate_checkout_login_jwt(user) do
      {:error, _reason} ->
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

  defp ensure_bigcommerce_user(user) do
    user = Recognizer.Repo.preload(user, :bigcommerce_user)

    if user.bigcommerce_user do
      user
    else
      case get_or_create_customer(user) do
        {:ok, _user} ->
          Recognizer.Repo.preload(user, :bigcommerce_user, force: true)

        {:error, _reason} ->
          user
      end
    end
  end
end

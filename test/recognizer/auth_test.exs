defmodule Recognizer.AuthTest do
  use Recognizer.DataCase

  import Recognizer.Factories

  alias Recognizer.Auth

  describe "exchange/2" do
    setup do
      %{token: audience_id} = insert(:audience)
      %{email: email} = insert(:user)
      {:ok, access_id, refresh_id} = Auth.login(email, "password", audience_id)

      context = [
        access_id: access_id,
        audience_id: audience_id,
        email: email,
        refresh_id: refresh_id
      ]

      {:ok, context}
    end

    test "returns a new access token for valid refresh tokens", %{
      audience_id: audience_id,
      access_id: access_id,
      refresh_id: refresh_id
    } do
      assert {:ok, new_access_id, ^refresh_id} = Auth.exchange(refresh_id, audience_id)

      assert access_id != new_access_id
    end

    test "returns an error when audience token is invalid", %{refresh_id: refresh_id} do
      assert {:error, "unable to verify claims"} =
               Auth.exchange(refresh_id, "invalid audience token")
    end

    test "returns an error when refresh token is invalid", %{
      audience_id: audience_id,
      email: email
    } do
      %{token: another_audience} = insert(:audience)

      {:ok, _access_id, another_refresh_id} = Auth.login(email, "password", another_audience)

      assert {:error, "unable to verify claims"} = Auth.exchange(another_refresh_id, audience_id)
    end
  end

  describe "login/3" do
    setup do
      %{id: audience_id} = insert(:audience)
      %{email: email} = insert(:user)

      {:ok, audience_id: audience_id, email: email}
    end

    test "returns new access and refresh tokens for valid credentials", %{
      audience_id: audience_id,
      email: email
    } do
      assert {:ok, access_id, refresh_id} = Auth.login(email, "password", audience_id)
      assert is_binary(access_id)
      assert is_binary(refresh_id)
    end

    test "returns an error for invalid credentials", %{
      audience_id: audience_id,
      email: email
    } do
      assert {:error, "authentication failed"} = Auth.login(email, "wrong password", audience_id)
    end

    test "returns an error for missing users", %{audience_id: audience_id} do
      assert {:error, "authentication failed"} =
               Auth.login("missing@example.com", "password", audience_id)
    end
  end
end

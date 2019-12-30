defmodule Recognizer.AuthTest do
  use Recognizer.DataCase

  import Recognizer.Factories

  alias Recognizer.Auth

  describe "exchange/2" do
    setup do
      %{token: audience_token} = insert(:audience)
      %{email: email} = insert(:user)
      {:ok, access_token, refresh_token} = Auth.login(email, "password", audience_token)

      context = [
        access_token: access_token,
        audience_token: audience_token,
        email: email,
        refresh_token: refresh_token
      ]

      {:ok, context}
    end

    test "returns a new access token for valid refresh tokens", %{
      audience_token: audience_token,
      access_token: access_token,
      refresh_token: refresh_token
    } do
      assert {:ok, new_access_token, ^refresh_token} =
               Auth.exchange(refresh_token, audience_token)

      assert access_token != new_access_token
    end

    test "returns an error when audience token is invalid", %{refresh_token: refresh_token} do
      assert :error = Auth.exchange(refresh_token, "invalid audience token")
    end

    test "returns an error when refresh token is invalid", %{
      audience_token: audience_token,
      email: email
    } do
      %{token: another_audience} = insert(:audience)

      {:ok, _access_token, another_refresh_token} =
        Auth.login(email, "password", another_audience)

      assert :error = Auth.exchange(another_refresh_token, audience_token)
    end
  end

  describe "login/3" do
    setup do
      %{token: audience_token} = insert(:audience)
      %{email: email} = insert(:user)

      {:ok, audience_token: audience_token, email: email}
    end

    test "returns new access and refresh tokens for valid credentials", %{
      audience_token: audience_token,
      email: email
    } do
      assert {:ok, access_token, refresh_token} = Auth.login(email, "password", audience_token)
      assert is_binary(access_token)
      assert is_binary(refresh_token)
    end

    test "returns an error for invalid credentials", %{
      audience_token: audience_token,
      email: email
    } do
      assert :error = Auth.login(email, "wrong password", audience_token)
    end

    test "returns an error for missing users", %{audience_token: audience_token} do
      assert :error = Auth.login("missing@example.com", "password", audience_token)
    end
  end
end

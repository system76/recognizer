defmodule Recognizer.BigCommerceTestHelpers do
  @moduledoc false

  def ok_bigcommerce_response() do
    body = Jason.encode!(%{data: [%{id: 1001}]})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}}
  end

  def empty_bigcommerce_response() do
    body = Jason.encode!(%{data: []})

    {:ok, %HTTPoison.Response{body: body, status_code: 200}}
  end

  def bad_bigcommerce_response() do
    body = Jason.encode!(%{errors: [%{failure: 1}]})

    {:ok, %HTTPoison.Response{body: body, status_code: 400}}
  end

  def limit_bigcommerce_response() do
    headers = [{"x-rate-limit-time-reset-ms", "1"}]

    {:ok, %HTTPoison.Response{status_code: 429, headers: headers}}
  end
end

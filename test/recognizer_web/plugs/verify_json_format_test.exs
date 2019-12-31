defmodule RecognizerWeb.Plugs.VerifyJSONFormatTest do
  use RecognizerWeb.ConnCase

  alias RecognizerWeb.Plugs.VerifyJSONFormat

  @opts VerifyJSONFormat.init([])

  test "passes through the conn for GET" do
    %Plug.Conn{state: state} =
      :get
      |> build_conn("/")
      |> VerifyJSONFormat.call(@opts)

    refute :sent == state
  end

  test "passes through the conn for DELETE" do
    %Plug.Conn{state: state} =
      :delete
      |> build_conn("/")
      |> put_req_header("content-type", "application/json")
      |> VerifyJSONFormat.call(@opts)

    refute :sent == state
  end

  test "passes through the conn when JSON has a \"data\" key" do
    parser_opts =
      Plug.Parsers.init(
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Jason
      )

    %Plug.Conn{state: state} =
      :post
      |> build_conn("/", Jason.encode!(%{data: %{}}))
      |> put_req_header("content-type", "application/json")
      |> Plug.Parsers.call(parser_opts)
      |> VerifyJSONFormat.call(@opts)

    refute :sent == state
  end

  test "returns a 400 when JSON is missing the \"data\" key" do
    assert %Plug.Conn{state: :sent, status: 400} =
             :post
             |> build_conn("/", Jason.encode!(%{}))
             |> put_req_header("content-type", "application/json")
             |> VerifyJSONFormat.call(@opts)
  end
end

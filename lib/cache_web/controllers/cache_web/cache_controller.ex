defmodule CacheWeb.CacheController do
  use CacheWeb, :controller

  alias Cache.CacheAgent

  @doc """
  Create account with given params.

  Params in POST body:
  name
  initial_amount

  Return:
  HTTP 204
  """
  def put(conn, params) do
    key = params["key"]
    val = params["value"]

    CacheAgent.put(key, val)

    send_resp(conn, 204, "")
  end

  def get(conn, params) do
    key = params["key"]
    val = CacheAgent.get(key)

    json(conn, %{value: val})
  end
end

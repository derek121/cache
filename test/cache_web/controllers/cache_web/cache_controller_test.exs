defmodule CacheWeb.CacheControllerTest do
  use CacheWeb.ConnCase

  test "put and get", %{conn: conn} do
    Cache.CacheAgent.clear_state()

    # Add and get for key "a"
    params = %{key: "a", value: 100}
    conn = post(conn, "/put", params)
    assert response(conn, 204)

    params = %{key: "a"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 100

    # Add and get different for key "a"
    params = %{key: "a", value: 101}
    conn = post(conn, "/put", params)
    assert response(conn, 204)

    params = %{key: "a"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 101

    # Add for keys "b" and "c"
    params = %{key: "b", value: 200}
    conn = post(conn, "/put", params)
    assert response(conn, 204)

    params = %{key: "c", value: 300}
    conn = post(conn, "/put", params)
    assert response(conn, 204)

    # Get all: "b", "c", "a"
    params = %{key: "b"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 200

    params = %{key: "c"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 300

    params = %{key: "a"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 101

    # Now "b" is the LRU, so should be evicted when adding new key
    params = %{key: "d", value: 400}
    conn = post(conn, "/put", params)
    assert response(conn, 204)

    # Get all, including "d". "b" should be nil now, due to being evicted
    params = %{key: "a"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 101

    params = %{key: "b"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == nil

    params = %{key: "c"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 300

    params = %{key: "d"}
    conn = get(conn, "/get", params)
    assert json_response(conn, 200)["value"] == 400
  end
end

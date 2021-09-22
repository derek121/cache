defmodule CacheWeb.Router do
  use CacheWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CacheWeb do
    pipe_through :api

    post "/put", CacheController, :put
    get  "/get", CacheController, :get
  end
end

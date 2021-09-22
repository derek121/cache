defmodule Cache.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CacheWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cache.PubSub},
      # Start the Endpoint (http/https)
      CacheWeb.Endpoint,
      # Start a worker by calling: Cache.Worker.start_link(arg)
      # {Cache.Worker, arg}

      #{Cache.CacheAgent, %{}}
      Cache.CacheAgent
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cache.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CacheWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

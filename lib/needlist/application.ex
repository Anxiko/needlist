defmodule Needlist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cachex, [Application.fetch_env!(:needlist, :cache_key)]},
      NeedlistWeb.Telemetry,
      Needlist.Repo,
      {DNSCluster, query: Application.get_env(:needlist, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Needlist.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Needlist.Finch},
      # Start a worker by calling: Needlist.Worker.start_link(arg)
      # {Needlist.Worker, arg},
      # Start to serve requests, typically the last entry
      NeedlistWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Needlist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NeedlistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

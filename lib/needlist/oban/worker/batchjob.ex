defmodule Needlist.Oban.Worker.Batchjob do
  @moduledoc """
  Worker for dispatching batch jobs, to be run by other workers.
  """

  use Oban.Worker,
    queue: :batchjob,
    max_attempts: 3,
    unique: [
      keys: [:type]
    ]

  alias Needlist.Users
  alias Needlist.Releases
  alias Needlist.Oban.Dispatcher
  alias Needlist.Repo.Release

  @scraping_limit Application.compile_env!(:needlist, :default_listings_scraping_limit)
  @timeout Application.compile_env!(:needlist, :oban_timeout)

  @impl true
  def perform(%Oban.Job{args: %{"type" => "wantlist"}} = job) do
    users = Users.all()
    usernames = Enum.map(users, & &1.username)

    Enum.reduce_while(usernames, :ok, fn username, :ok ->
      case Dispatcher.dispatch_wantlist(username) do
        {:ok, _job} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {username, reason}}}
      end
    end)
    |> case do
      :ok -> notify_finished(job)
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(%Oban.Job{args: %{"type" => "listings"}} = job) do
    releases = Releases.outdated_listings(limit: @scraping_limit)

    Enum.reduce_while(releases, :ok, fn %Release{id: release_id}, :ok ->
      case Dispatcher.dispatch_listings(release_id) do
        {:ok, _job} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {release_id, reason}}}
      end
    end)
    |> case do
      :ok -> notify_finished(job)
      {:error, reason} -> {:error, reason}
    end
  end

  defp notify_finished(%Oban.Job{} = job) do
    case Needlist.PubSub.job_finished(__MODULE__, job) do
      :ok -> :ok
      {:error, details} -> {:error, {:notify, details}}
    end
  end

  @impl true
  def timeout(_job), do: @timeout
end

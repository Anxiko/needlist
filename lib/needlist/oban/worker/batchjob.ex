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

  @impl true
  def perform(%Oban.Job{args: %{"type" => "wantlist"}}) do
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
  end

  def perform(%Oban.Job{args: %{"type" => "listings"}}) do
    releases = Releases.outdated_listings(limit: @scraping_limit)

    Enum.reduce_while(releases, :ok, fn %Release{id: release_id}, :ok ->
      case Dispatcher.dispatch_listings(release_id) do
        {:ok, _job} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {release_id, reason}}}
      end
    end)
  end
end

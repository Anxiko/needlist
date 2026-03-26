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

    usernames
    |> Enum.reduce_while(:ok, fn username, :ok ->
      case Dispatcher.dispatch_wantlist(username) do
        {:ok, _job} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {username, reason}}}
      end
    end)
    |> tap(&report_job_status(&1, job))
  end

  def perform(%Oban.Job{args: %{"type" => "listings"}} = job) do
    releases = Releases.outdated_listings(limit: @scraping_limit)

    releases
    |> Enum.reduce_while(:ok, fn %Release{id: release_id}, :ok ->
      case Dispatcher.dispatch_listings(release_id) do
        {:ok, _job} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {release_id, reason}}}
      end
    end)
    |> tap(&report_job_status(&1, job))
  end

  @impl true
  def timeout(_job), do: @timeout

  defp report_job_status(:ok, %Oban.Job{} = job) do
    Needlist.PubSub.job_finished(__MODULE__, job)
  end

  defp report_job_status({:error, _reason}, %Oban.Job{} = job) when job.attempt == job.max_attempts do
    Needlist.PubSub.job_failed(__MODULE__, job)
  end

  defp report_job_status(_result, %Oban.Job{}), do: :ok
end

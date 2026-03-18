defmodule Needlist.Oban.Worker.Wantlist do
  @moduledoc """
  Worker for scrapping a user's wantlist from Discogs.
  """

  @unique_period Application.compile_env!(:needlist, :wantlist_update_interval_seconds)
  @timeout Application.compile_env!(:needlist, :oban_timeout)

  use Oban.Worker,
    queue: :wantlist,
    max_attempts: 3,
    unique: [
      period: @unique_period,
      keys: [:username]
    ]

  @impl true
  def perform(%Oban.Job{} = job) do
    case do_perform(job) do
      :ok ->
        Needlist.PubSub.job_finished(__MODULE__, job)
        :ok

      {:error, error} ->
        if job.attempt == job.max_attempts do
          Needlist.PubSub.job_failed(__MODULE__, job)
        end

        {:error, error}
    end
  end

  @spec do_perform(Oban.Job.t()) :: :ok | {:error, any()}
  defp do_perform(%Oban.Job{args: %{"username" => username}}) do
    try do
      case Needlist.Discogs.Scraper.scrape_wantlist(username) do
        :ok -> :ok
        {:error, error} -> {:error, {:scrape, error}}
      end
    rescue
      e -> {:error, {:exception, Exception.message(e)}}
    end
  end

  @impl true
  def timeout(_job), do: @timeout
end

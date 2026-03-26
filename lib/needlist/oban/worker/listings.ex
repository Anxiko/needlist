defmodule Needlist.Oban.Worker.Listings do
  @moduledoc """
  Worker for scrapping a release's listings from Discogs.
  """

  @unique_period Application.compile_env!(:needlist, :oban_unique_period)
  @timeout Application.compile_env!(:needlist, :oban_timeout)

  use Oban.Worker,
    queue: :listings,
    max_attempts: 3,
    unique: [
      period: @unique_period,
      keys: [:release_id]
    ]

  @impl true
  def perform(%Oban.Job{args: %{"release_id" => release_id}} = job) do
    case Needlist.Discogs.Scraper.scrape_listings({:release, release_id}) do
      %{ok: [^release_id]} ->
        Needlist.PubSub.job_finished(__MODULE__, job)
        :ok

      %{error: [{^release_id, step, details}]} ->
        if job.attempt == job.max_attempts do
          Needlist.PubSub.job_failed(__MODULE__, job)
        end

        {:error, {step, details}}
    end
  end

  @impl true
  def timeout(_job), do: @timeout
end

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
  def perform(%Oban.Job{args: %{"release_id" => release_id}}) do
    case Needlist.Discogs.Scraper.scrape_listings({:release, release_id}) do
      %{ok: [^release_id]} ->
        :ok

      %{error: [{^release_id, step, details}]} ->
        {:error, {step, details}}
    end
  end

  @impl true
  def timeout(_job), do: @timeout
end

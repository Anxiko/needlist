defmodule Needlist.Oban.Worker.Listings do
  @moduledoc """
  Worker for scrapping a release's listings from Discogs.
  """

  @unique_period Application.compile_env!(:needlist, :oban_unique_period)

  use Oban.Worker,
    queue: :listings,
    max_attempts: 3,
    unique: [
      period: @unique_period,
      keys: [:release_id]
    ]

  # 1 minute
  @timeout_ms 1_000 * 60

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
  def timeout(%Oban.Job{}), do: @timeout_ms
end

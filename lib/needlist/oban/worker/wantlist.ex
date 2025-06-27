defmodule Needlist.Oban.Worker.Wantlist do
  @moduledoc """
  Worker for scrapping a user's wantlist from Discogs.
  """

  @unique_period Application.compile_env!(:needlist, :oban_unique_period)

  use Oban.Worker,
    queue: :wantlist,
    max_attempts: 3,
    unique: [
      period: @unique_period,
      keys: [:username]
    ]

  # 1 minute
  @timeout_ms 1_000 * 60

  @impl true
  def perform(%Oban.Job{args: %{"username" => username}}) do
    Needlist.Discogs.Scraper.scrape_wantlist(username)
  end

  @impl true
  def timeout(%Oban.Job{}), do: @timeout_ms
end

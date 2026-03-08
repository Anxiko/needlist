defmodule Needlist.Oban.Worker.Wantlist do
  @moduledoc """
  Worker for scrapping a user's wantlist from Discogs.
  """

  @unique_period Application.compile_env!(:needlist, :oban_unique_period)
  @timeout Application.compile_env!(:needlist, :oban_timeout)

  use Oban.Worker,
    queue: :wantlist,
    max_attempts: 3,
    unique: [
      period: @unique_period,
      keys: [:username]
    ]

  @impl true
  def perform(%Oban.Job{args: %{"username" => username}} = job) do
    :ok = Needlist.Discogs.Scraper.scrape_wantlist(username)

    case Needlist.PubSub.job_finished(__MODULE__, job) do
      :ok -> :ok
      {:error, details} -> {:error, {:notify, details}}
    end
  end

  @impl true
  def timeout(_job), do: @timeout
end

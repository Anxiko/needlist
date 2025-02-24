defmodule Mix.Tasks.ScrapeMany do
  @moduledoc """
  Scrape outdated (or non-existent) listings for many releases, up to a limit of releases
  """


  require Logger
  alias Nullables.Result
  alias Needlist.Repo.Listing
  alias Needlist.Discogs.Scraper
  alias Needlist.Repo.Release
  alias Needlist.Releases

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run([limit]) do
    aggregated_results =
      limit
      |> String.to_integer()
      |> then(&Releases.outdated_listings(limit: &1))
      |> Task.async_stream(__MODULE__, :scrape_release, [], timeout: 15 * 1_000, on_timeout: :kill_task)
      |> Stream.map(&Result.unwrap!/1)
      |> Enum.group_by(
        fn {_release_id, {ok_or_error, _result}} -> ok_or_error end,
        fn {release_id, _} -> release_id end
      )

    ok_results = Map.get(aggregated_results, :ok, [])
    error_results = Map.get(aggregated_results, :error, [])

    Logger.info("Total processed: #{length(ok_results) + length(error_results)}")
    Logger.info("Processed OK: #{inspect(ok_results, charlists: :as_lists)}")
    Logger.warning("Processed error: #{inspect(error_results, charlists: :as_lists)}")
  end

  @spec scrape_release(Release.t()) :: {integer(), {:ok, Release.t()} | {:error, any()}}
  def scrape_release(%Release{id: release_id} = release) do
    Logger.debug("Starting #{release_id}")

    release_id
    |> Scraper.scrape_listings()
    |> Result.flat_map(fn listings ->
      listings
      |> Enum.map(&Listing.params_from_scrapped(&1, release_id))
      |> then(&Releases.update_active_listings(release, &1))
    end)
    |> tap(fn result ->
      case result do
        {:ok, _release} -> Logger.info("Scrapped #{release_id}")
        {:error, error} -> Logger.warning("Failed to scrape #{release_id}: #{inspect(error)}")
      end
    end)
    |> then(&{release_id, &1})
  end
end

defmodule Mix.Tasks.ScrapeMany do
  @moduledoc false
  require Logger
  alias Nullables.Result
  alias Needlist.Repo.Listing
  alias Needlist.Discogs.Scraper
  alias Needlist.Repo.Want
  alias Needlist.Wants

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run([limit]) do
    aggregated_results =
      limit
      |> String.to_integer()
      |> then(&Wants.outdated_listings(limit: &1))
      |> Task.async_stream(__MODULE__, :scrape_want, [], timeout: 15 * 1_000, on_timeout: :kill_task)
      |> Stream.map(&Result.unwrap!/1)
      |> Enum.group_by(
        fn {_want_id, {ok_or_error, _result}} -> ok_or_error end,
        fn {want_id, _} -> want_id end
      )

    ok_results = Map.get(aggregated_results, :ok, [])
    error_results = Map.get(aggregated_results, :error, [])

    Logger.info("Total processed: #{length(ok_results) + length(error_results)}")
    Logger.info("Processed OK: #{inspect(ok_results, charlists: :as_lists)}")
    Logger.warning("Processed error: #{inspect(error_results, charlists: :as_lists)}")
  end

  @spec scrape_want(Want.t()) :: {integer(), {:ok, Want.t()} | {:error, any()}}
  def scrape_want(%Want{id: want_id} = want) do
    Logger.debug("Starting #{want_id}")

    want_id
    |> Scraper.scrape_listings()
    |> Result.flat_map(fn listings ->
      listings
      |> Enum.map(&Listing.params_from_scrapped(&1, want_id))
      |> then(&Wants.update_active_listings(want, &1))
    end)
    |> tap(fn result ->
      case result do
        {:ok, _want} -> Logger.info("Scrapped #{want_id}")
        {:error, error} -> Logger.warning("Failed to scrape #{want_id}: #{inspect(error)}")
      end
    end)
    |> then(&{want_id, &1})
  end
end

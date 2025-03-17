defmodule Needlist.Discogs.Scraper do
  @moduledoc """
  High level scraping operations.
  """

  alias Needlist.Repo.Listing
  alias Needlist.Repo
  alias Needlist.Repo.Release
  alias Needlist.Releases
  alias Nullables.Result
  alias Needlist.Discogs.Scraper.Listing, as: ListingScraper

  @type listings_src() :: {:release, integer() | [integer()]} | {:outdated, keyword()}

  @spec scrape_listings(src :: listings_src()) :: Result.result([Release.t()])
  def scrape_listings(src) do
    src
    |> releases_from_source()
    |> Task.async_stream(
      fn release ->
        with {:ok, listings} <- ListingScraper.scrape_listings(release.id) do
          listings = Enum.map(listings, &Listing.params_from_scraped(&1, release.id))
          {:ok, {release, listings}}
        end
      end,
      timeout: 15 * 1_000,
      on_timeout: :kill_task
    )
    |> Stream.map(fn
      {:ok, {:ok, pair}} -> {:ok, pair}
      {:ok, {:error, reason}} -> {:error, {:listing, reason}}
      {:error, reason} -> {:error, {:task, reason}}
    end)
    |> Result.try_reduce()
    |> Result.map(fn pairs ->
      Repo.transaction(fn ->
        Enum.map(pairs, fn {release, listings} ->
          case Releases.update_active_listings(release, listings) do
            {:ok, release} -> release
            {:error, error} -> Repo.rollback(error)
          end
        end)
      end)
    end)
  end

  @spec releases_from_source(listings_src()) :: [Release.t()]
  defp releases_from_source({:release, id_or_ids}) when is_integer(id_or_ids) or is_list(id_or_ids) do
    id_or_ids
    |> List.wrap()
    |> Releases.get_many_by_id()
  end

  defp releases_from_source({:outdated, options}) do
    options
    |> Releases.outdated_listings()
  end
end

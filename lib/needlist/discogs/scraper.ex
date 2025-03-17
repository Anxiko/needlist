defmodule Needlist.Discogs.Scraper do
  @moduledoc """
  High level scraping operations.
  """

  alias Needlist.Discogs.Api
  alias Needlist.Repo
  alias Needlist.Repo.Listing
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Pagination.PageInfo
  alias Needlist.Repo.Release
  alias Needlist.Repo.Want
  alias Needlist.Repo.Wantlist
  alias Needlist.Releases
  alias Needlist.Users
  alias Needlist.Wantlists
  alias Nullables.Result
  alias Needlist.Discogs.Scraper.Listing, as: ListingScraper

  @type listings_src() :: {:release, integer() | [integer()]} | {:outdated, keyword()}

  @per_page 500

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
    |> Result.map(&insert_release_listings_pairs/1)
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

  @spec insert_release_listings_pairs([{Release.t(), [Listing.t()]}]) :: Result.result([Release.t()])
  defp insert_release_listings_pairs(pairs) do
    Repo.transaction(fn ->
      Enum.map(pairs, fn {release, listings} ->
        case Releases.update_active_listings(release, listings) do
          {:ok, release} -> release
          {:error, error} -> Repo.rollback(error)
        end
      end)
    end)
  end

  @spec scrape_wantlist(username :: String.t()) :: :ok
  def scrape_wantlist(username) do
    {:ok, user_from_api} = Api.get_user(username)
    {:ok, wants} = get_needlist(username)

    Repo.transaction(fn ->
      user =
        case Users.get_by_username(username) do
          {:ok, existing} ->
            existing

          {:error, :not_found} ->
            Repo.insert!(user_from_api)
        end

      wants
      |> Enum.map(fn want ->
        {:ok, want} = Release.from_want(want)
        want
      end)
      |> Enum.each(&Repo.insert(&1, on_conflict: :replace_all, conflict_target: :id))

      release_ids = MapSet.new(wants, fn %Want{id: id} -> id end)

      username
      |> Wantlists.by_username()
      |> Enum.filter(fn %Wantlist{release_id: release_id} -> not MapSet.member?(release_ids, release_id) end)
      |> Enum.each(&Repo.delete!(&1))

      wants
      |> Enum.map(fn want ->
        {:ok, want} = Wantlist.from_scraped_want(want, user.id)
        want
      end)
      |> Enum.each(
        &Repo.insert(&1, on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:user_id, :release_id])
      )
    end)
    |> case do
      {:ok, :ok} -> :ok
      {:error, _details} = error -> error
    end
  end

  @spec get_needlist(String.t()) :: Result.result([Want.t()])
  defp get_needlist(username) do
    1
    |> Stream.iterate(&Kernel.+(&1, 1))
    |> Stream.map(&Api.get_user_needlist(username, per_page: @per_page, page: &1))
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, %Pagination{items: items, page_info: page_info}}, {:ok, pages} ->
        pages = [items | pages]

        cont_or_halt = if PageInfo.last_page?(page_info), do: :halt, else: :cont
        {cont_or_halt, {:ok, pages}}

      {:error, _} = error, _acc ->
        {:halt, error}
    end)
    |> Result.map(fn pages ->
      pages
      |> Enum.reverse()
      |> Enum.concat()
    end)
  end
end

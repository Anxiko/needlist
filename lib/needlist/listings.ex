defmodule Needlist.Listings do
  @moduledoc """
  Context for listings on Discogs for a release.
  """

  alias Ecto.Changeset
  alias Needlist.Repo
  alias Needlist.Repo.Listing

  @spec by_want_id(integer(), boolean() | :any) :: [Listing.t()]
  @spec by_want_id(integer()) :: [Listing.t()]
  def by_want_id(want_id, active_status \\ true) do
    Listing
    |> Listing.filter_by_active(active_status)
    |> Listing.by_want_id(want_id)
    |> Repo.all()
  end

  @spec update_release_listings(integer(), [map()], DateTime.t()) :: {:ok, [Listing.t()]} | {:error, Changeset.t()}
  @spec update_release_listings(integer(), [map()]) :: {:ok, [Listing.t()]} | {:error, Changeset.t()}
  def update_release_listings(want_id, active_listings, timestamp \\ DateTime.utc_now()) do
    mapped_active_listings =
      Map.new(active_listings, fn %{id: id} = params ->
        {id, {:new, params}}
      end)

    want_id
    |> by_want_id(:any)
    |> Map.new(fn %Listing{id: id} = listing -> {id, {:current, listing}} end)
    |> Map.merge(mapped_active_listings, fn _key, {:current, current_listing}, {:new, params} ->
      {:updated, current_listing, params}
    end)
    |> Map.values()
    |> Enum.map(fn
      # Was present, not in active listings, mark inactive
      {:current, listing} ->
        Listing.changeset(listing, %{active: false})

      # Was present, is in active listings, update and mark as active
      {:updated, listing, params} ->
        Listing.changeset(listing, Map.put(params, :active, true))

      # New entry, was not present, create it
      {:new, params} ->
        Listing.changeset(Listing.new(), Map.merge(params, %{active: true, inserted_at: timestamp}))
    end)
    |> Enum.map(&Listing.changeset(&1, %{updated_at: timestamp}))
    |> insert_changesets()
  end

  @spec insert_changesets([Changeset.t()]) :: {:ok, [Listing.t()]} | {:error, Changeset.t()}
  defp insert_changesets(changesets) do
    Repo.transaction(fn ->
      changesets
      |> Stream.map(&Repo.insert_or_update/1)
      |> Enum.reduce_while([], fn
        {:ok, listing}, listings ->
          {:cont, [listing | listings]}

        {:error, _changeset} = error, _acc ->
          {:halt, error}
      end)
    end)
    |> case do
      {:ok, listings} ->
        {:ok, Enum.reverse(listings)}

      {:error, _changeset} = error ->
        Repo.rollback(error)
    end
  end
end

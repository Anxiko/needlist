defmodule Needlist.Releases do
  @moduledoc """
  Context for releases
  """

  alias Nullables.Result
  alias Ecto.Changeset

  alias Needlist.Repo
  alias Needlist.Repo.Release
  alias Needlist.Listings

  @spec all :: [Release.t()]
  def all do
    Release.named_binding()
    |> Release.with_listings()
    |> Release.with_users()
    |> Release.with_price_stats()
    |> Repo.all()
  end

  @spec get_by_id(release_id :: integer()) :: Result.result(Release.t(), :not_found)
  def get_by_id(release_id) do
    Release
    |> Release.by_id(release_id)
    |> Repo.one()
    |> Nullables.nullable_to_result(:not_found)
  end

  @spec update_active_listings(Release.t(), [map()]) :: {:ok, Release.t()} | {:error, Changeset.t()}
  def update_active_listings(%Release{id: release_id} = release, active_listings) do
    timestamp = DateTime.utc_now()

    Repo.transaction(fn ->
      with {:ok, _listings} <- Listings.update_release_listings(release_id, active_listings, timestamp),
           changeset = Release.changeset(release, %{listings_last_updated: timestamp}),
           {:ok, want} <- Repo.update(changeset) do
        want
      else
        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end

  @spec outdated_listings(Keyword.t()) :: [Release.t()]
  @spec outdated_listings() :: [Release.t()]
  def outdated_listings(args \\ []) do
    expiration = Keyword.get(args, :expiration)
    limit = Keyword.get(args, :limit)

    Release.named_binding()
    |> Release.filter_by_outdated_listings(expiration)
    |> Release.filter_by_wanted_by_someone()
    |> Release.maybe_limit(limit)
    |> Repo.all()
  end
end

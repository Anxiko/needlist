defmodule Needlist.Wants do
  @moduledoc """
  Wantlist context.
  """

  alias Ecto.Changeset
  alias Needlist.Listings
  alias Needlist.Repo
  alias Needlist.Repo.Want

  @type sort_key() :: Want.sort_key()
  @type sort_order() :: Want.sort_order()

  @type needlist_page_options() :: [
          page: pos_integer(),
          per_page: pos_integer(),
          sort: sort_key(),
          sort_order: sort_order()
        ]

  @spec all :: [Want.t()]
  def all do
    Want.named_binding()
    |> Want.with_users()
    |> Want.with_listings()
    |> Want.with_price_stats()
    |> Repo.all()
  end

  @spec get_needlist_page(String.t(), needlist_page_options()) :: [Want.t()]
  @spec get_needlist_page(String.t()) :: [Want.t()]
  def get_needlist_page(username, options \\ []) do
    page = Keyword.get(options, :page, 1)
    per_page = Keyword.get(options, :per_page, 50)
    sort_key = Keyword.get(options, :sort, :label)
    sort_order = Keyword.get(options, :sort_order, :asc)

    Want.named_binding()
    |> Want.in_user_needlist_by_username(username)
    |> Want.with_price_stats()
    |> Want.sort_by(sort_key, sort_order)
    |> Want.paginated(page, per_page)
    |> Repo.all()
  end

  @spec get_by_id(integer()) :: {:ok, Want.t()} | {:error, :not_found}
  def get_by_id(want_id) do
    Want
    |> Want.by_id(want_id)
    |> Repo.one()
    |> Nullables.nullable_to_result(:not_found)
  end

  @spec needlist_size(String.t()) :: non_neg_integer()
  def needlist_size(username) do
    Want.named_binding()
    |> Want.in_user_needlist_by_username(username)
    |> Repo.aggregate(:count)
  end

  @spec outdated_listings(Keyword.t()) :: [Want.t()]
  @spec outdated_listings() :: [Want.t()]
  def outdated_listings(args \\ []) do
    expiration = Keyword.get(args, :expiration)
    limit = Keyword.get(args, :limit)

    Want
    |> Want.filter_by_outdated_listings(expiration)
    |> Want.maybe_limit(limit)
    |> Repo.all()
  end

  @spec update_active_listings(Want.t(), [map()]) :: {:ok, Want.t()} | {:error, Changeset.t()}
  def update_active_listings(%Want{id: want_id} = want, active_listings) do
    timestamp = DateTime.utc_now()

    Repo.transaction(fn ->
      with {:ok, _listings} <- Listings.update_release_listings(want_id, active_listings, timestamp),
           changeset = Want.changeset(want, %{listings_last_updated: timestamp}),
           {:ok, want} <- Repo.update(changeset) do
        want
      else
        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end

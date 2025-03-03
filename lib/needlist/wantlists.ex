defmodule Needlist.Wantlists do
  @moduledoc """
  Context for wantlists
  """

  alias Needlist.Discogs.Api
  alias Needlist.Repo.Want
  alias Nullables.Result
  alias Needlist.Repo
  alias Needlist.Repo.Wantlist
  alias Needlist.Types.QueryOptions

  @default_currency Application.compile_env!(:money, :default_currency) |> Atom.to_string()

  @spec get_needlist_page(username :: String.t(), options :: QueryOptions.options()) :: [Wantlist.t()]
  @spec get_needlist_page(username :: String.t()) :: [Wantlist.t()]
  def get_needlist_page(username, options \\ []) do
    {:ok, %QueryOptions{page: page, per_page: per_page, sort: sort_key, sort_order: sort_order}} =
      QueryOptions.parse(options)

    Wantlist.named_binding()
    |> Wantlist.with_release(@default_currency)
    |> Wantlist.with_user()
    |> Wantlist.by_username(username)
    |> Wantlist.sort_by(sort_key, sort_order)
    |> Wantlist.paginated(page, per_page)
    |> Repo.all()
  end

  @spec needlist_size(String.t()) :: non_neg_integer()
  def needlist_size(username) do
    Wantlist.named_binding()
    |> Wantlist.with_user()
    |> Wantlist.by_username(username)
    |> Repo.aggregate(:count)
  end

  @spec by_username(username :: String.t()) :: [Wantlist.t()]
  def by_username(username) do
    Wantlist.named_binding()
    |> Wantlist.with_user()
    |> Wantlist.by_username(username)
    |> Repo.all()
  end

  @spec from_view(username :: binary(), release_id :: integer()) :: Result.result(Wantlist.t(), :not_found)
  def from_view(username, release_id) do
    Wantlist.named_binding()
    |> Wantlist.with_user()
    |> Wantlist.with_release(@default_currency)
    |> Wantlist.by_username(username)
    |> Wantlist.by_release_id(release_id)
    |> Repo.one()
    |> Nullables.nullable_to_result(:not_found)
  end

  @spec update_wantlist(username :: binary(), release_id :: integer(), params :: keyword()) ::
          Result.result(Wantlist.t())
  def update_wantlist(username, release_id, params) do
    with {:ok, wantlist} <- from_view(username, release_id),
         {:ok, _want} <-
           Api.update_user_wantlist_entry(username, release_id, params) do
      wantlist
      |> Wantlist.changeset(Map.new(params))
      |> Repo.update()
    end
  end
end

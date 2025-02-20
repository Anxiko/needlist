defmodule Needlist.Wantlists do
  @moduledoc """
  Context for wantlists
  """

  alias Needlist.Repo
  alias Needlist.Repo.Wantlist
  alias Needlist.Types.QueryOptions

  @spec get_needlist_page(username :: String.t(), options :: QueryOptions.options()) :: [Wantlist.t()]
  @spec get_needlist_page(username :: String.t()) :: [Wantlist.t()]
  def get_needlist_page(username, options \\ []) do
    {:ok, %QueryOptions{page: page, per_page: per_page, sort: sort_key, sort_order: sort_order}} =
      QueryOptions.parse(options)

    Wantlist.named_binding()
    |> Wantlist.with_release()
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
end

defmodule Needlist.Wantlists do
  @moduledoc """
  Context for wantlists
  """

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
end

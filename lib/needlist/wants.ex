defmodule Needlist.Wants do
  @moduledoc """
  Wantlist context.
  """

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

  @spec get_needlist_page(String.t(), needlist_page_options()) :: [Want.t()]
  @spec get_needlist_page(String.t()) :: [Want.t()]
  def get_needlist_page(username, options \\ []) do
    page = Keyword.get(options, :page, 1)
    per_page = Keyword.get(options, :per_page, 50)
    sort_key = Keyword.get(options, :sort, :label)
    sort_order = Keyword.get(options, :sort_order, :asc)

    Want
    |> Want.in_user_needlist_by_username(username)
    |> Want.sort_by(sort_key, sort_order)
    |> Want.paginated(page, per_page)
    |> Repo.all()
  end
end

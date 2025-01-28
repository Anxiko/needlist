defmodule Needlist.Types.QueryOptions do
  @moduledoc """
  Sort and pagination options for needlist querying, through Discogs API or within Needlist
  """

  alias Needlist.Types.QueryOptions.SortOrder
  alias Needlist.Types.QueryOptions.SortKey

  @type options() :: [
          page: pos_integer(),
          per_page: pos_integer(),
          sort: SortKey.t(),
          sort_order: SortOrder.t()
        ]
end

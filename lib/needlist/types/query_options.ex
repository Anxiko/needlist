defmodule Needlist.Types.QueryOptions do
  @moduledoc """
  Sort and pagination options for needlist querying, through Discogs API or within Needlist
  """

  alias Nullables.Result
  alias Needlist.Types.QueryOptions.SortOrder
  alias Needlist.Types.QueryOptions.SortKey

  @default [page: 1, per_page: 50, sort: :label, sort_order: :asc]
  defstruct @default

  @type t() :: %__MODULE__{
          page: pos_integer(),
          per_page: pos_integer(),
          sort: SortKey.t(),
          sort_order: SortOrder.t()
        }

  @type options() :: [
          page: pos_integer(),
          per_page: pos_integer(),
          sort: SortKey.t(),
          sort_order: SortOrder.t()
        ]

  @spec parse(keyword()) :: Result.result(t(), atom())
  def parse(options) do
    case Keyword.validate(options, @default) do
      {:ok, options} ->
        page = Keyword.get(options, :page, 1)
        per_page = Keyword.get(options, :per_page, 50)
        sort_key = Keyword.get(options, :sort, :label)
        sort_order = Keyword.get(options, :sort_order, :asc)

        {:ok,
         %__MODULE__{
           page: page,
           per_page: per_page,
           sort: sort_key,
           sort_order: sort_order
         }}

      {:error, _keys} = error ->
        error
    end
  end

  @spec default() :: options()
  def default do
    @default
  end
end

defmodule Needlist.Discogs.Pagination do
  @moduledoc """
  Discogs API paginated response, containing both items and page info
  """

  alias Needlist.Discogs.Pagination.PageInfo
  alias Needlist.Discogs.Parsing

  @keys [:page_info, :data]

  @enforce_keys @keys
  defstruct @keys

  @type t(data) :: %__MODULE__{page_info: PageInfo.t(), data: [data]}

  @spec parse_page(map(), String.t(), (map() -> item)) :: {:ok, t(item)} | :error when item: var
  def parse_page(%{"pagination" => pagination} = payload, items_key, parse_one) do
    with {:ok, items} <- Map.fetch(payload, items_key),
         {:ok, page_info} <- PageInfo.parse(pagination),
         {:ok, items} <- Parsing.parse_many(items, parse_one) do
      {:ok, %__MODULE__{page_info: page_info, data: items}}
    end
  end
end

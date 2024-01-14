defmodule Needlist.Discogs.Pagination.Page do
  @moduledoc """
  Contains both items and page infor for a paginated Discogs API response
  """

  alias Needlist.Discogs.Pagination
  alias Needlist.Discogs.Parsing

  @keys [:pagination, :data]

  @enforce_keys @keys
  defstruct @keys

  @type t(data) :: %__MODULE__{pagination: Pagination.t(), data: [data]}

  @spec parse_page(map(), String.t(), (map() -> item)) :: {:ok, t(item)} | :error when item: var
  def parse_page(%{"pagination" => pagination} = payload, items_key, parse_one) do
    with {:ok, items} <- Map.fetch(payload, items_key),
         {:ok, pagination} <- Pagination.parse(pagination),
         {:ok, items} <- Parsing.parse_many(items, parse_one) do
      {:ok, %__MODULE__{pagination: pagination, data: items}}
    end
  end
end

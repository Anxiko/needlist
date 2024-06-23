defmodule Needlist.Repo.Pagination do
  @moduledoc """
  Parses and holds paginated API responses into a normalized schema.
  """

  alias Needlist.Repo.Pagination.Page
  alias Needlist.Repo.Pagination.Page.Schema, as: PageSchema

  alias Needlist.Repo.Pagination.PageInfo

  alias Nullables.Result

  defstruct [:page_info, :items]

  @type t(item) :: %__MODULE__{
          page_info: PageInfo.t(),
          items: [item]
        }

  @type t() :: t(any())

  @spec parse(
          params :: map(),
          items_key :: atom(),
          item_type :: item_type
        ) :: Result.result(t(item_type))
        when item_type: var
  def parse(params, items_key, item_type) do
    page_schema = PageSchema.new(items_key, item_type)

    params
    |> Page.parse(page_schema)
    |> Result.map(&from_page/1)
    |> Result.map_error(fn %Ecto.Changeset{errors: errors} -> errors end)
  end

  defp from_page(%Page{schema: %PageSchema{items_key: items_key}, data: %{pagination: page_info} = data}) do
    %__MODULE__{
      page_info: page_info,
      items: Map.fetch!(data, items_key)
    }
  end
end

defmodule Needlist.Repo.Pagination do
  alias Needlist.Discogs.Pagination.PageInfo

  alias Ecto.Changeset

  defstruct [:page_info, :items]

  @type t(item) :: %__MODULE__{
          page_info: PageInfo.t(),
          items: [item]
        }

  @type t() :: t(any())

  @required_fields [:page_info, :items]
  @optional_fields []
  @embedded_fields [:items]
  @items @required_fields ++ @optional_fields ++ @embedded_fields

  @spec parse(
          params :: map(),
          items_key :: String.t(),
          item_type :: item_type
        ) :: Ecto.Changeset.t(t(item_type))
        when item_type: var
  def parse(params, items_key, item_type) do
    params = rename_items(params, items_key)
    types = %{page_info: PageInfo, items: {:array, item_type}}

    {%__MODULE__{}, types}
    |> Changeset.cast(params, @items)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
  end

  @spec rename_items(map(), String.t()) :: map()
  defp rename_items(params, items_key) do
    MapUtils.rename_existing(params, items_key, "items")
  end
end

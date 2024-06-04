defmodule Needlist.Repo.Pagination.Page.Schema do
  alias Needlist.Repo.Pagination.PageInfo

  @type items_type() :: module()

  @keys [:items_key, :items_type]

  @type t() :: %__MODULE__{
          items_key: atom(),
          items_type: items_type()
        }

  @enforce_keys @keys
  defstruct @keys

  @spec new(atom(), items_type()) :: t()
  def new(items_key, items_type) do
    %__MODULE__{items_key: items_key, items_type: items_type}
  end

  @spec types(t()) :: map()
  def types(%__MODULE__{items_key: items_key, items_type: items_type}) do
    %{pagination: PageInfo}
    |> Map.put(items_key, {:array, items_type})
  end

  @spec keys(t()) :: [atom()]
  def keys(%__MODULE__{} = schema) do
    schema
    |> types()
    |> Map.keys()
  end

  @spec items_key(t()) :: atom()
  def items_key(%__MODULE__{items_key: items_key}), do: items_key
end

defmodule NeedlistWeb.NeedlistLive.State do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Api.Types

  @required_fields [:page, :per_page, :sort_key, :sort_order]
  @optional_fields [:max_pages]
  @fields @required_fields ++ @optional_fields

  @serializable_fields @required_fields

  @primary_key false
  embedded_schema do
    field :page, :integer, default: 1
    field :max_pages, :integer, default: nil
    field :per_page, :integer, default: 25
    field :sort_key, Ecto.Enum, values: Types.SortKey.values(), default: Types.SortKey.label()
    field :sort_order, Ecto.Enum, values: Types.SortOrder.values(), default: Types.SortOrder.asc()
  end

  @type t() :: %__MODULE__{
          page: pos_integer(),
          max_pages: pos_integer() | nil,
          per_page: pos_integer(),
          sort_key: Types.SortKey.t(),
          sort_order: Types.SortOrder.t()
        }

  @spec default() :: t()
  def default() do
    changeset(%__MODULE__{}, %{})
    |> Changeset.apply_action!(:default)
  end

  @spec parse(map()) :: t()
  def parse(params) do
    %__MODULE__{}
    |> changeset(params)
    |> remove_errors(params)
    |> Changeset.apply_action!(:parse)
  end

  @spec update(t(), map()) :: {:ok, t()} | {:error, Changeset.t()}
  def update(state, params) do
    state
    |> changeset(params)
    |> Changeset.apply_action(:update)
  end

  @spec changeset(t(), map()) :: Changeset.t()
  def changeset(state, params) do
    state
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> Changeset.validate_number(:page, greater_than_or_equal_to: 1)
    |> Changeset.validate_number(:max_pages, greater_than_or_equal_to: 1)
    |> Changeset.validate_number(:per_page, greater_than_or_equal_to: 1)
    |> validate_page_under_limit()
  end

  @spec as_params(t()) :: map()
  def as_params(%__MODULE__{} = state) do
    state
    |> Map.from_struct()
    |> Map.take(@serializable_fields)
    |> MapUtils.atoms_as_strings()
  end

  @spec as_needlist_options(t()) :: Api.needlist_options()
  def as_needlist_options(state) do
    state
    |> Map.from_struct()
    |> Map.take(@serializable_fields)
    |> MapUtils.rename_existing(:sort_key, :sort)
    |> Map.filter(fn {_k, v} -> v != nil end)
    |> Keyword.new()
  end

  @spec validate_page_under_limit(Changeset.t()) :: Changeset.t()
  defp validate_page_under_limit(changeset) do
    with {:ok, max_pages} <- Changeset.fetch_change(changeset, :max_pages),
         {:ok, page} when page > max_pages <- Changeset.fetch_change(changeset, :page) do
      Changeset.put_change(changeset, :page, max_pages)
    else
      _ -> changeset
    end
  end

  @spec remove_errors(Changeset.t(), map()) :: Changeset.t()
  defp remove_errors(%Changeset{valid?: true} = changeset, _params), do: changeset

  defp remove_errors(%Changeset{errors: errors} = changeset, params) do
    fields_in_error = errors |> Keyword.keys() |> Enum.map(&Atom.to_string/1)
    params = Map.filter(params, fn {k, _v} -> to_string(k) not in fields_in_error end)

    changeset(changeset.data, params)
  end
end

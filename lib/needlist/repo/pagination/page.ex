defmodule Needlist.Repo.Pagination.Page do
  alias Needlist.Repo.Pagination.Page.Schema

  @enforce_keys [:schema]
  defstruct [:schema, data: %{}]

  @type data() :: map()

  @type t() :: %__MODULE__{
          schema: Schema.t(),
          data: map()
        }

  @spec new(Schema.t()) :: t()
  @spec new(data(), Schema.t()) :: t()
  def new(data \\ %{}, schema) do
    %__MODULE__{data: data, schema: schema}
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{schema: schema} = page, params \\ %{}) do
    keys = Schema.keys(schema)

    page
    |> schemaless_data()
    |> Ecto.Changeset.cast(params, keys)
    |> Ecto.Changeset.validate_required(keys)
  end

  @spec parse(Schema.t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def parse(schema, params) do
    schema
    |> new()
    |> changeset(params)
    |> Ecto.Changeset.apply_action(:parse)
    |> Nullables.Result.map(&new(&1, schema))
  end

  defp schemaless_data(%__MODULE__{data: data, schema: schema}) do
    {data, Schema.types(schema)}
  end
end

defmodule Needlist.Repo.Pagination.PageInfo do
  @moduledoc """
  Info about the pagination of a query result.
  """

  use Ecto.Schema

  alias Ecto.Changeset

  alias Needlist.Repo.Pagination.Urls

  @required_fields [:page, :pages, :per_page, :items]
  @optional_fields []
  @embedded_fields [:urls]

  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :page, :integer
    field :pages, :integer
    field :per_page, :integer
    field :items, :integer
    embeds_one :urls, Urls, on_replace: :update
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          page: pos_integer(),
          pages: pos_integer(),
          per_page: non_neg_integer(),
          items: non_neg_integer(),
          urls: Urls.t()
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.validate_number(:page, [:pos])
    |> EctoExtra.validate_number(:pages, [:pos])
    |> EctoExtra.validate_number(:per_page, [:non_neg])
    |> EctoExtra.validate_number(:items, [:non_neg])
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{
      page: 1,
      pages: 1,
      per_page: 1,
      items: 0,
      urls: Urls.new()
    }
  end
end

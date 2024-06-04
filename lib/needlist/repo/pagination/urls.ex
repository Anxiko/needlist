defmodule Needlist.Repo.Pagination.Urls do
  use Ecto.Schema

  alias Ecto.Changeset

  @required_fields []
  @optional_fields [:first, :last, :prev, :next]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :first, :string
    field :last, :string
    field :prev, :string
    field :next, :string
  end

  @type t() :: %__MODULE__{
          first: String.t() | nil,
          last: String.t() | nil,
          prev: String.t() | nil,
          next: String.t() | nil
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t()
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
  end

  @spec new() :: t()
  def new(), do: %__MODULE__{}
end

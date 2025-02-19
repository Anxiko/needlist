defmodule Needlist.Repo.Want.Format do
  @moduledoc """
  Format in which a release is a available.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  @derive EctoExtra.DumpableSchema

  @required_fields [:name, :qty]
  @optional_fields [:descriptions]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :name, :string
    field :qty, :integer
    field :descriptions, {:array, :string}, default: []
  end

  @type t() :: %__MODULE__{
          name: String.t(),
          qty: non_neg_integer(),
          descriptions: [String.t()]
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Ecto.Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> Changeset.validate_number(:qty, greater_than_or_equal_to: 0)
  end
end

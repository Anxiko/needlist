defmodule Needlist.Repo.Want.Label do
  use Ecto.Schema

  alias Ecto.Changeset

  @required_fields [:id, :name, :catno, :resource_url]
  @optional_fields []
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: false
    field :name, :string
    field :catno, :string
    field :resource_url, :string
  end

  @type t() :: %__MODULE__{
          id: integer(),
          name: String.t(),
          catno: String.t(),
          resource_url: String.t()
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
  end
end

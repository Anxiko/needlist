defmodule Needlist.Repo.Want.Artist do
  use Ecto.Schema

  alias Ecto.Changeset

  @required_fields [:id, :name, :resource_url]
  @optional_fields [:join, :anv]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: true
    field :name, :string
    field :anv, :string
    field :resource_url, :string
    field :join, :string, default: nil
  end

  @type t() :: %__MODULE__{
          id: integer(),
          name: String.t(),
          anv: String.t() | nil,
          resource_url: String.t(),
          join: String.t() | nil
        }

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
  end
end

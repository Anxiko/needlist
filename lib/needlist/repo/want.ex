defmodule Needlist.Repo.Want do
  use Ecto.Schema

  alias Ecto.Changeset
  alias EctoExtra
  alias Needlist.Repo.Want.BasicInformation

  @required_fields [:id]
  @optional_fields []
  @embedded_fields [:basic_information]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "wantlist" do
    field :id, :id, primary_key: true
    embeds_one :basic_information, BasicInformation, on_replace: :update
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          id: integer() | nil,
          basic_information: BasicInformation.t() | nil
        }

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(map()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end
end

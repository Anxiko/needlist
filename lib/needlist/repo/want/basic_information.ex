defmodule Needlist.Repo.Want.BasicInformation do
  use Ecto.Schema

  @required_fields [:id, :master_id, :title]
  @optional_fields [:year]
  @embedded_fields [:artists, :labels, :formats]
  @fields @required_fields ++ @optional_fields

  alias Ecto.Changeset

  alias Needlist.Repo.Want.Artist
  alias Needlist.Repo.Want.Format
  alias Needlist.Repo.Want.Label

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: true
    field :master_id, :id
    field :title, :string
    field :year, :integer

    embeds_many :artists, Artist, on_replace: :delete
    embeds_many :labels, Label, on_replace: :delete
    embeds_many :formats, Format, on_replace: :delete
  end

  @type t() :: %__MODULE__{
          id: integer() | nil,
          master_id: integer() | nil,
          title: String.t() | nil,
          year: non_neg_integer() | nil,
          artists: [Artist.t()] | nil,
          labels: [Label.t()] | nil,
          formats: [Format.t()] | nil
        }

  use EctoExtra.SchemaType, schema: __MODULE__

  @spec changeset(t(), map()) :: Changeset.t(t())
  @spec changeset(t()) :: Changeset.t(t())
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

defmodule Needlist.Repo.Want do
  @moduledoc """
  Entry in a user's wantlist.
  """

  use Ecto.Schema

  alias Ecto.Changeset
  alias EctoExtra.DumpableSchema
  alias Needlist.Repo.Want.BasicInformation
  alias Needlist.Repo.Want.Artist
  alias Needlist.Repo.Want.Label
  alias Money.Ecto.Composite.Type, as: MoneyEcto

  @required_fields [:id, :date_added]
  @optional_fields [:listings_last_updated, :notes, :rating]
  @embedded_fields [:basic_information]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  embedded_schema do
    field :id, :id, primary_key: true
    field :display_artists, :string
    field :display_labels, :string
    field :date_added, :utc_datetime
    field :listings_last_updated, :utc_datetime
    field :notes, :string
    field :rating, :integer
    field :min_price, MoneyEcto, virtual: true
    field :max_price, MoneyEcto, virtual: true
    field :avg_price, MoneyEcto, virtual: true
    embeds_one :basic_information, BasicInformation, on_replace: :update
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          id: integer(),
          display_artists: String.t(),
          display_labels: String.t(),
          date_added: DateTime.t(),
          listings_last_updated: DateTime.t() | nil,
          notes: String.t() | nil,
          rating: non_neg_integer() | nil,
          min_price: Money.t() | nil,
          max_price: Money.t() | nil,
          avg_price: Money.t() | nil,
          basic_information: BasicInformation.t()
        }

  @type sort_order() :: :asc | :desc | :asc_nulls_last | :desc_nulls_last
  @type sort_key() :: :artist | :title | :label | :added | :min_price | :avg_price | :max_price | :year

  @spec changeset(%__MODULE__{} | t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(map()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.validate_number(:rating, [:non_neg])
    |> EctoExtra.cast_many_embeds(@embedded_fields)
    |> compute_sorting_fields()
  end

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{}
  end

  defp compute_sorting_fields(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> Changeset.fetch_field(:basic_information)
    |> case do
      {_source, %BasicInformation{artists: artists, labels: labels}} ->
        changeset
        |> Changeset.put_change(:display_artists, Artist.display_artists(artists))
        |> Changeset.put_change(:display_labels, Label.display_labels(labels))

      _ ->
        changeset
    end
  end

  defp compute_sorting_fields(changeset), do: changeset

  defimpl DumpableSchema do
    @spec dump(Needlist.Repo.Want.t()) :: map()
    def dump(want) do
      want
      |> Map.from_struct()
      |> Map.take([
        :id,
        :display_artists,
        :display_labels,
        :date_added,
        :listings_last_updated,
        :notes,
        :basic_information
      ])
      |> DumpableSchema.Embeds.dump_embed_fields([:basic_information])
    end
  end
end

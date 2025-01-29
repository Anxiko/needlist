defmodule Needlist.Repo.Release do
  @moduledoc """
  Basic information about a release, as extracted from a user's wantlist.
  """

  use Ecto.Schema

  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset

  alias Nullables.Result
  alias Needlist.Repo.Listing
  alias Needlist.Repo.Want
  alias Needlist.Repo.Want.Artist
  alias Needlist.Repo.Want.Format
  alias Needlist.Repo.Want.Label

  @required [:id, :master_id, :title]
  @optional [:year]
  @embedded [:artists, :labels, :formats]

  @type t() :: %__MODULE__{
          id: integer(),
          master_id: integer(),
          title: String.t(),
          year: integer() | nil,
          artists: [Artist.t()] | nil,
          labels: [Label.t()] | nil,
          formats: [Format.t()] | nil,
          listings: [Listing.t()] | NotLoaded.t()
        }

  @primary_key false
  schema "releases" do
    field :id, :id, primary_key: true
    field :master_id, :id
    field :title, :string
    field :year, :integer

    embeds_many :artists, Artist, on_replace: :delete
    embeds_many :labels, Label, on_replace: :delete
    embeds_many :formats, Format, on_replace: :delete

    has_many :listings, Listing, references: :id
  end

  @spec changeset(release :: t() | %__MODULE__{}, params :: map()) :: Changeset.t(t())
  @spec changeset(params :: map()) :: Changeset.t(t())
  def changeset(release \\ %__MODULE__{}, params) do
    release
    |> Changeset.cast(params, @required ++ @optional)
    |> Changeset.validate_required(@required)
    |> EctoExtra.cast_many_embeds(@embedded)
  end

  @spec from_want(Want.t()) :: Result.result(t(), Changeset.t(t()))
  def from_want(%Want{id: id, basic_information: basic_information}) do
    basic_information
    |> EctoExtra.DumpableSchema.dump()
    |> Map.put(:id, id)
    |> changeset()
    |> Changeset.apply_action(:cast)
  end
end

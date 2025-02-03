defmodule Needlist.Repo.Release do
  @moduledoc """
  Basic information about a release, as extracted from a user's wantlist.
  """

  use Ecto.Schema

  import Ecto.Query
  import EctoExtra, only: [nullable_amount_to_money: 2]

  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset
  alias Money.Ecto.Composite.Type, as: MoneyEcto

  alias Nullables.Result
  alias Needlist.Repo.Listing
  alias Needlist.Repo.User
  alias Needlist.Repo.Want
  alias Needlist.Repo.Want.Artist
  alias Needlist.Repo.Want.Format
  alias Needlist.Repo.Want.Label

  @default_currency Application.compile_env!(:money, :default_currency) |> Atom.to_string()

  @required [:id, :master_id, :title]
  @optional [:year, :listings_last_updated]
  @embedded [:artists, :labels, :formats]

  @type t() :: %__MODULE__{
          id: integer(),
          master_id: integer(),
          title: String.t(),
          year: integer() | nil,
          listings_last_updated: DateTime.t() | nil,
          display_artists: String.t(),
          display_labels: String.t(),
          min_price: Money.t() | nil,
          max_price: Money.t() | nil,
          avg_price: Money.t() | nil,
          artists: [Artist.t()],
          labels: [Label.t()],
          formats: [Format.t()],
          listings: [Listing.t()] | NotLoaded.t(),
          users: [User.t()] | NotLoaded.t()
        }

  @primary_key false
  schema "releases" do
    field :id, :id, primary_key: true
    field :master_id, :id
    field :title, :string
    field :year, :integer
    field :listings_last_updated, :utc_datetime

    field :display_artists, :string
    field :display_labels, :string

    field :min_price, MoneyEcto, virtual: true
    field :max_price, MoneyEcto, virtual: true
    field :avg_price, MoneyEcto, virtual: true

    embeds_many :artists, Artist, on_replace: :delete
    embeds_many :labels, Label, on_replace: :delete
    embeds_many :formats, Format, on_replace: :delete

    has_many :listings, Listing, references: :id
    many_to_many :users, User, join_through: "wantlist"
  end

  @spec changeset(release :: t() | %__MODULE__{}, params :: map()) :: Changeset.t(t())
  @spec changeset(params :: map()) :: Changeset.t(t())
  def changeset(release \\ %__MODULE__{}, params) do
    release
    |> Changeset.cast(params, @required ++ @optional)
    |> Changeset.validate_required(@required)
    |> EctoExtra.cast_many_embeds(@embedded)
    |> compute_sorting_fields()
  end

  @spec from_want(Want.t()) :: Result.result(t(), Changeset.t(t()))
  def from_want(%Want{id: id, basic_information: basic_information}) do
    basic_information
    |> EctoExtra.DumpableSchema.dump()
    |> Map.put(:id, id)
    |> changeset()
    |> Changeset.apply_action(:cast)
  end

  @spec named_binding() :: Ecto.Query.t()
  def named_binding() do
    from __MODULE__, as: :releases
  end

  @spec with_listings(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec with_listings() :: Ecto.Query.t()
  def with_listings(query \\ __MODULE__) do
    preload(query, :listings)
  end

  @spec with_users(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec with_users() :: Ecto.Query.t()
  def with_users(query \\ __MODULE__) do
    preload(query, :users)
  end

  @spec wanted_by_username(query :: Ecto.Query.t() | __MODULE__, username :: String.t()) :: Ecto.Query.t()
  @spec wanted_by_username(username :: String.t()) :: Ecto.Query.t()
  def wanted_by_username(query \\ __MODULE__, username) do
    query
    |> join(:inner, [releases: r], u in assoc(r, :users), as: :users)
    |> where([users: u], u.username == ^username)
    |> select_merge([releases: r], r)
  end

  @spec with_price_stats(Ecto.Query.t() | __MODULE__, String.t()) :: Ecto.Query.t()
  @spec with_price_stats(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  def with_price_stats(query, currency \\ @default_currency) do
    query
    |> join(:left, [releases: r], l in subquery(Listing.pricing_for_release(currency)),
      on: r.id == l.release_id,
      as: :listings
    )
    |> select_merge([releases: r, listings: l], %{
      r
      | min_price: nullable_amount_to_money(l.min_price, ^currency),
        max_price: nullable_amount_to_money(l.max_price, ^currency),
        avg_price: nullable_amount_to_money(l.avg_price, ^currency)
    })
  end

  @spec compute_sorting_fields(Changeset.t(t())) :: Changeset.t(t())
  defp compute_sorting_fields(%Ecto.Changeset{valid?: true} = changeset) do
    artists = Changeset.fetch_field!(changeset, :artists)
    labels = Changeset.fetch_field!(changeset, :labels)

    changeset
    |> Changeset.put_change(:display_artists, Artist.display_artists(artists))
    |> Changeset.put_change(:display_labels, Label.display_labels(labels))
  end

  defp compute_sorting_fields(changeset), do: changeset
end

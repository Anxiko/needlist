defmodule Needlist.Repo.Want do
  @moduledoc """
  Entry in a user's wantlist.
  """

  use Ecto.Schema

  import Ecto.Query

  alias Needlist.Repo.Want
  alias Needlist.Repo.Listing
  alias Ecto.Changeset
  alias EctoExtra
  alias Needlist.Repo.Want.BasicInformation
  alias Needlist.Repo.User
  alias Needlist.Repo.Want.Artist
  alias Needlist.Repo.Want.Label
  alias Money.Ecto.Composite.Type, as: MoneyEcto

  @required_fields [:id, :date_added]
  @optional_fields [:min_price, :listings_last_updated]
  @embedded_fields [:basic_information]
  @fields @required_fields ++ @optional_fields

  @default_currency Application.compile_env!(:money, :default_currency) |> Atom.to_string()
  @default_listing_expiration Duration.new!(week: 1)

  @primary_key false
  schema "wants" do
    field :id, :id, primary_key: true
    field :display_artists, :string
    field :display_labels, :string
    field :date_added, :utc_datetime
    field :listings_last_updated, :utc_datetime
    field :min_price, MoneyEcto, virtual: true
    field :max_price, MoneyEcto, virtual: true
    field :avg_price, MoneyEcto, virtual: true
    embeds_one :basic_information, BasicInformation, on_replace: :update
    many_to_many :users, User, join_through: "user_wantlist"
    has_many :listings, Listing, references: :id
  end

  use EctoExtra.SchemaType, schema: __MODULE__

  @type t() :: %__MODULE__{
          id: integer() | nil,
          display_artists: String.t() | nil,
          display_labels: String.t() | nil,
          date_added: DateTime.t() | nil,
          listings_last_updated: DateTime.t() | nil,
          min_price: Money.t() | nil,
          basic_information: BasicInformation.t() | nil
        }

  @type sort_order() :: :asc | :desc
  @type sort_key() :: :artist | :title | :label | :added | :price | :year

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(map()) :: Changeset.t(t())
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, @fields)
    |> Changeset.validate_required(@required_fields)
    |> EctoExtra.cast_many_embeds(@embedded_fields)
    |> compute_sorting_fields()
  end

  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @spec named_binding() :: Ecto.Query.t()
  def named_binding() do
    from(Want, as: :wants)
  end

  @spec by_id(Ecto.Query.t() | __MODULE__, integer()) :: Ecto.Query.t()
  @spec by_id(integer()) :: Ecto.Query.t()
  def by_id(query \\ __MODULE__, want_id) do
    where(query, id: ^want_id)
  end

  @spec in_user_needlist(Ecto.Query.t() | __MODULE__, integer()) :: Ecto.Query.t()
  @spec in_user_needlist(integer()) :: Ecto.Query.t()
  def in_user_needlist(query \\ __MODULE__, user_id) do
    query
    |> join(:inner, [wants: w], u in assoc(w, :users), as: :users)
    |> where([users: u], u.id == ^user_id)
    |> select_merge([wants: w], w)
  end

  @spec in_user_needlist_by_username(Ecto.Query.t() | __MODULE__, String.t()) :: Ecto.Query.t()
  @spec in_user_needlist_by_username(String.t()) :: Ecto.Query.t()
  def in_user_needlist_by_username(query \\ __MODULE__, username) do
    query
    |> join(:inner, [wants: w], u in assoc(w, :users), as: :users)
    |> where([users: u], u.username == ^username)
    |> select_merge([wants: w], w)
  end

  @spec sort_by_artists(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_artists(sort_order()) :: Ecto.Query.t()
  def sort_by_artists(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([{^order, :display_artists}])
  end

  @spec sort_by_title(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_title(sort_order()) :: Ecto.Query.t()
  def sort_by_title(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([w], [{^order, fragment("?->>?", w.basic_information, "title")}])
  end

  @spec sort_by_labels(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_labels(sort_order()) :: Ecto.Query.t()
  def sort_by_labels(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([{^order, :display_labels}])
  end

  @spec sort_by_date_added(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_date_added(sort_order()) :: Ecto.Query.t()
  def sort_by_date_added(query \\ __MODULE__, order) do
    query
    |> Ecto.Query.order_by([{^order, :date_added}])
  end

  @spec sort_by_price(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  @spec sort_by_price(sort_order()) :: Ecto.Query.t()
  def sort_by_price(query \\ __MODULE__, order) do
    query
    |> order_by([listings: l], [{^order, l.total_price}])
  end

  @spec sort_by_year(Ecto.Query.t() | __MODULE__, sort_order()) :: Ecto.Query.t()
  def sort_by_year(query \\ __MODULE__, order) do
    query
    |> order_by([wants: w], [{^order, fragment("?->?", w.basic_information, "year")}])
  end

  @spec sort_by(Ecto.Query.t() | __MODULE__, sort_key(), sort_order()) :: Ecto.Query.t()
  @spec sort_by(sort_key(), sort_order()) :: Ecto.Query.t()
  def sort_by(query \\ __MODULE__, sort_key, sort_order)
  def sort_by(query, :artist, sort_order), do: sort_by_artists(query, sort_order)
  def sort_by(query, :title, sort_order), do: sort_by_title(query, sort_order)
  def sort_by(query, :label, sort_order), do: sort_by_labels(query, sort_order)
  def sort_by(query, :added, sort_order), do: sort_by_date_added(query, sort_order)
  def sort_by(query, :price, sort_order), do: sort_by_price(query, sort_order)
  def sort_by(query, :year, sort_order), do: sort_by_year(query, sort_order)

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

  @spec paginated(Ecto.Query.t() | __MODULE__, pos_integer(), pos_integer()) :: Ecto.Query.t()
  @spec paginated(pos_integer(), pos_integer()) :: Ecto.Query.t()
  def paginated(query \\ __MODULE__, page, per_page) do
    offset = per_page * (page - 1)

    query
    |> limit(^per_page)
    |> offset(^offset)
  end

  @spec with_listings(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec with_listings() :: Ecto.Query.t()
  def with_listings(query \\ __MODULE__) do
    preload(query, :listings)
  end

  @spec with_price_stats(Ecto.Query.t() | __MODULE__, String.t()) :: Ecto.Query.t()
  @spec with_price_stats(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec with_price_stats() :: Ecto.Query.t()
  def with_price_stats(query \\ __MODULE__, currency \\ @default_currency) do
    query
    |> join(:left, [wants: w], l in subquery(pricing_subquery(currency)),
      on: w.id == l.want_id,
      as: :listings
    )
    |> select_merge([wants: w, listings: l], %{
      w
      | min_price: l.min_price,
        max_price: l.max_price,
        avg_price: l.avg_price
    })
  end

  @spec filter_by_outdated_listings(Ecto.Query.t() | __MODULE__, DateTime.t() | Duration.t() | nil) :: Ecto.Query.t()
  @spec filter_by_outdated_listings(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec filter_by_outdated_listings() :: Ecto.Query.t()
  def filter_by_outdated_listings(query \\ __MODULE__, listings_expiration \\ @default_listing_expiration) do
    conditions = dynamic([w], is_nil(w.listings_last_updated) or ^maybe_filter_by_expiration(listings_expiration))

    query
    |> where(^conditions)
    |> order_by([w], asc_nulls_last: w.listings_last_updated)
  end

  @spec maybe_limit(Ecto.Query.t() | __MODULE__, non_neg_integer() | nil) :: Ecto.Query.t()
  @spec maybe_limit(non_neg_integer()) :: Ecto.Query.t()
  def maybe_limit(query \\ __MODULE__, limit)
  def maybe_limit(query, nil), do: query
  def maybe_limit(query, limit), do: limit(query, ^limit)

  @spec pricing_subquery(String.t()) :: Ecto.Query.t()
  defp pricing_subquery(currency) do
    Listing
    |> Listing.by_total_price_currency(currency)
    |> Listing.pricing_stats()
  end

  defp maybe_filter_by_expiration(nil), do: false

  defp maybe_filter_by_expiration(%DateTime{} = expiration) do
    dynamic([w], w.listings_last_updated <= ^expiration)
  end

  defp maybe_filter_by_expiration(%Duration{} = duration) do
    DateTime.utc_now()
    |> DateTime.shift(Duration.negate(duration))
    |> maybe_filter_by_expiration()
  end
end

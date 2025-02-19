defmodule Needlist.Repo.Listing do
  @moduledoc """
  Listing of a release on sale
  """

  use Ecto.Schema
  import Ecto.Query

  alias Needlist.Repo.Want
  alias Needlist.Repo.Release
  alias Needlist.Discogs.Scraper

  alias Money.Ecto.Composite.Type, as: MoneyEcto
  alias Ecto.Changeset

  @required_fields [
    :id,
    :media_condition,
    :want_id,
    :base_price
  ]
  @optional_fields [:release_id, :sleeve_condition, :total_price, :shipping_price, :active, :inserted_at, :updated_at]
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "listings" do
    field :id, :id, primary_key: true
    belongs_to :want, Want
    belongs_to :release, Release
    field :media_condition, :string
    field :sleeve_condition, :string
    field :base_price, MoneyEcto
    field :shipping_price, MoneyEcto
    field :total_price, MoneyEcto
    field :active, :boolean, default: true
    timestamps()
  end

  @type t() :: %__MODULE__{}

  @spec new() :: t()
  def new(), do: %__MODULE__{}

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(t() | Changeset.t(t())) :: Changeset.t(t())
  def changeset(listing, params \\ %{}) do
    listing
    |> Changeset.cast(params, @fields)
    |> Changeset.cast_assoc(:want)
    |> Changeset.validate_required(@required_fields)
  end

  @spec params_from_scrapped(Scraper.t(), integer()) :: map()
  def params_from_scrapped(%Scraper{} = scrapper, release_id) do
    %Scraper{
      price: %Scraper.Price{
        base: base_price,
        shipping: shipping_price,
        total: total_price
      },
      description: %Scraper.Description{
        media_condition: media_condition,
        sleeve_condition: sleeve_condition,
        listing_id: id
      }
    } = scrapper

    %{
      id: id,
      want_id: release_id,
      media_condition: media_condition,
      sleeve_condition: sleeve_condition,
      base_price: base_price,
      shipping_price: shipping_price,
      total_price: total_price
    }
  end

  @spec filter_by_active(Ecto.Query.t() | __MODULE__, boolean() | :any) :: Ecto.Query.t()
  def filter_by_active(query \\ __MODULE__, active)

  def filter_by_active(query, :any), do: query
  def filter_by_active(query, active), do: where(query, active: ^active)

  @spec by_want_id(Ecto.Query.t() | __MODULE__, integer()) :: Ecto.Query.t()
  @spec by_want_id(integer()) :: Ecto.Query.t()
  def by_want_id(query \\ __MODULE__, want_id) do
    query
    |> where(want_id: ^want_id)
  end

  @spec by_total_price_currency(Ecto.Query.t() | __MODULE__, String.t() | atom()) :: Ecto.Query.t()
  @spec by_total_price_currency(String.t() | atom()) :: Ecto.Query.t()
  def by_total_price_currency(query \\ __MODULE__, currency) do
    query
    |> where([l], fragment("(?).currency", l.total_price) == ^currency)
  end

  @spec ranked_pricing_per_want(Ecto.Query.t() | __MODULE__) :: Ecto.Query.t()
  @spec ranked_pricing_per_want() :: Ecto.Query.t()
  def ranked_pricing_per_want(query \\ __MODULE__) do
    query
    |> windows([l], price_per_want_asc: [partition_by: l.want_id, order_by: fragment("(?).amount", l.total_price)])
    |> select([l], %{
      want_id: l.want_id,
      total_price: l.total_price,
      row_number: over(row_number(), :price_per_want_asc)
    })
  end

  @spec pricing_for_want(currency :: String.t() | atom()) :: Ecto.Query.t()
  def pricing_for_want(currency) do
    __MODULE__
    |> by_total_price_currency(currency)
    |> pricing_stats(:want_id)
  end

  @spec pricing_for_release(currency :: String.t() | atom()) :: Ecto.Query.t()
  def pricing_for_release(currency) do
    __MODULE__
    |> by_total_price_currency(currency)
    |> pricing_stats(:release_id)
  end

  @spec pricing_stats(query :: Ecto.Query.t(), group_by :: atom()) :: Ecto.Query.t()
  defp pricing_stats(query, group_by) do
    query
    |> group_by(^group_by)
    |> select(
      [l],
      %{
        ^group_by => field(l, ^group_by),
        min_price: min(fragment("(?).amount", l.total_price)),
        max_price: max(fragment("(?).amount", l.total_price)),
        avg_price: type(avg(fragment("(?).amount", l.total_price)), :integer)
      }
    )
  end
end

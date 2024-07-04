defmodule Needlist.Repo.Listing do
  @moduledoc """
  Listing of a release on sale
  """

  use Ecto.Schema

  alias Needlist.Repo.Want
  alias Needlist.Discogs.Scraper

  alias Money.Ecto.Composite.Type, as: MoneyEcto
  alias Ecto.Changeset

  @required_fields [
    :id,
    :media_condition,
    :want_id,
    :sleeve_condition,
    :base_price,
    :shipping_price,
    :total_price
  ]
  @optional_fields []
  @fields @required_fields ++ @optional_fields

  @primary_key false
  schema "listings" do
    field :id, :id, primary_key: true
    belongs_to :want, Want
    field :media_condition, :string
    field :sleeve_condition, :string
    field :base_price, MoneyEcto
    field :shipping_price, MoneyEcto
    field :total_price, MoneyEcto
  end

  @type t() :: %__MODULE__{}

  @spec changeset(t() | Changeset.t(t()), map()) :: Changeset.t(t())
  @spec changeset(t() | Changeset.t(t())) :: Changeset.t(t())
  def changeset(listing, params \\ %{}) do
    listing
    |> Changeset.cast(params, @fields)
    |> Changeset.cast_assoc(:want)
    |> Changeset.validate_required(@required_fields)
  end

  @spec changeset_from_scrapped(Scraper.t(), integer()) :: Ecto.Changeset.t(t())
  def changeset_from_scrapped(%Scraper{} = scrapper, release_id) do
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

    params = %{
      id: id,
      want_id: release_id,
      media_condition: media_condition,
      sleeve_condition: sleeve_condition,
      base_price: base_price,
      shipping_price: shipping_price,
      total_price: total_price
    }

    changeset(%__MODULE__{}, params)
  end
end

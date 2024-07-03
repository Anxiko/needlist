defmodule Needlist.Discogs.Scraper do
  @moduledoc """
  Scrape lists of listings from Discogs webpage
  """

  alias Needlist.Discogs.Scraper.Description
  alias Needlist.Discogs.Scraper.Price
  alias Nullables.Result

  @keys [:description, :price]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          description: Description.t(),
          price: Price.t()
        }

  @spec scrape_listings(integer()) :: Result.result([t])
  def scrape_listings(release_id) do
    release_id
    |> download()
    |> Result.flat_map(&parse/1)
  end

  @spec download(integer()) :: {:ok, Floki.html_tree()} | {:error, any}
  def download(release_id) do
    release_id
    |> Needlist.Python.scrape_listings()
    |> Nullables.Result.flat_map(&Floki.parse_document/1)
  end

  @spec parse(Floki.html_tree()) :: Result.result([t()])
  def parse(html_tree) do
    html_tree
    |> Floki.find(~s/tr[data-release-id]/)
    |> Enum.map(&parse_row/1)
    |> Result.try_reduce()
  end

  @spec parse_row(Floki.html_node()) :: Result.result(t())
  defp parse_row(row) do
    with {_, {:ok, description}} <- {:description, Description.parse(row)},
         {_, {:ok, price}} <- {:price, Price.parse(row)} do
      {:ok, %__MODULE__{description: description, price: price}}
    else
      {step, {:error, error}} -> {:error, {step, error}}
    end
  end
end

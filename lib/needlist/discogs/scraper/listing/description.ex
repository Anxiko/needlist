defmodule Needlist.Discogs.Scraper.Listing.Description do
  @moduledoc false

  @href_listing_pattern ~r"/sell/item/(?P<listing_id>\d+)$"

  @keys [:listing_id, :media_condition, :sleeve_condition]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          listing_id: integer(),
          media_condition: String.t(),
          sleeve_condition: String.t() | nil
        }

  import Needlist.Discogs.Scraper.Listing.Parsing, only: [node_outer_text: 1]

  @spec parse(Floki.html_node()) :: {:ok, t()} | {:error, any()}
  def parse(row) do
    with {_, [item_description]} <- {:description, Floki.find(row, "td.item_description")},
         {_, {:ok, listing_id}} <- {:listing_id, parse_listing_id(item_description)},
         {_, [item_condition]} <- {:condition, Floki.find(item_description, "p.item_condition")},
         {_, {:ok, {media, sleeve}}} <- {:parsing, parse_conditions(item_condition)} do
      {:ok, %__MODULE__{media_condition: media, sleeve_condition: sleeve, listing_id: listing_id}}
    else
      {step, :error} -> {:error, step}
      {step, {:error, details}} -> {:error, {step, details}}
      {step, details} -> {:error, {step, details}}
    end
  end

  @spec parse_conditions(Floki.html_node()) :: {:ok, {String.t(), String.t() | nil}} | {:error, any()}
  defp parse_conditions(item_condition) do
    item_condition
    |> Floki.find("p > span")
    |> Floki.filter_out(".mplabel")
    |> Enum.map(&node_outer_text/1)
    |> case do
      [media, sleeve] -> {:ok, {media, sleeve}}
      [media] -> {:ok, {media, nil}}
      _ -> {:error, {:conditions, item_condition}}
    end
  end

  @spec parse_listing_id(Floki.html_node()) :: {:ok, integer()} | :error
  defp parse_listing_id(item_description) do
    item_description
    |> Floki.attribute(~s(a[href^="/sell/item/"]), "href")
    |> Enum.map(fn href ->
      @href_listing_pattern
      |> Regex.named_captures(href)
      |> case do
        %{"listing_id" => listing_id} -> String.to_integer(listing_id)
        _ -> nil
      end
    end)
    |> Enum.filter(&(not is_nil(&1)))
    |> case do
      [listing_id] -> {:ok, listing_id}
      _ -> :error
    end
  end
end

defmodule Needlist.Discogs.Scraper.Price do
  @moduledoc """
  Parse the price information of a listing obtained through the scrapper
  """

  @raw_price_pattern ~r/\+?(?P<currency>[^\d]+)(?P<value>[\d\.]+)$/
  @free_shipping "+no extra shipping"

  import Needlist.Discogs.Scraper.Parsing, only: [node_outer_text: 1]

  @keys [:base, :shipping, :total]
  @enforce_keys @keys

  defstruct @keys

  @type t() :: %__MODULE__{
          base: Money.t(),
          shipping: Money.t(),
          total: Money.t()
        }

  @spec parse(Floki.html_node()) :: {:ok, t()} | {:error, any()}
  def parse(listing_row) do
    with {_, [item_price]} <- {:item_price, Floki.find(listing_row, "td.item_price")},
         {_, {:ok, base_price}} <- {:base_price, parse_base_price(item_price)},
         {_, {:ok, shipping_price}} <- {:shipping_price, parse_shipping_price(item_price)},
         {_, {:ok, total_price}} <- {:total_price, parse_total_price(item_price)} do
      {:ok,
       %__MODULE__{
         base: base_price,
         shipping: shipping_price,
         total: total_price
       }}
    else
      {step, :error} -> {:error, step}
      {step, details} -> {:error, {step, details}}
    end
  end

  @spec parse_base_price(Floki.html_node()) :: {:ok, Money.t()} | :error
  defp parse_base_price(item_price) do
    with [price] <- Floki.find(item_price, ".price"),
         [currency] <- Floki.attribute(price, "data-currency"),
         [raw_value] <- Floki.attribute(price, "data-pricevalue"),
         {:ok, money} <- Money.parse(raw_value, currency) do
      {:ok, money}
    else
      _ -> :error
    end
  end

  @spec parse_shipping_price(Floki.html_node()) :: {:ok, Money.t()} | :error
  defp parse_shipping_price(item_price) do
    with [shipping_price_node] <- Floki.find(item_price, ".item_shipping"),
         raw_shipping_price <- node_outer_text(shipping_price_node) do
      parse_raw_price(raw_shipping_price)
    else
      _ -> :error
    end
  end

  @spec parse_total_price(Floki.html_node()) :: {:ok, Money.t()} | :error
  defp parse_total_price(item_price) do
    with [total_price_node] <- Floki.find(item_price, ".converted_price"),
         raw_total_price <- node_outer_text(total_price_node),
         {:ok, total_price} <- parse_raw_price(raw_total_price) do
      {:ok, total_price}
    else
      _ -> :error
    end
  end

  defp parse_raw_price(@free_shipping), do: {:ok, Money.new(0)}

  @spec parse_raw_price(String.t()) :: {:ok, Money.t()} | :error
  defp parse_raw_price(raw_shipping_price) do
    raw_shipping_price = String.trim(raw_shipping_price)

    with %{"currency" => raw_currency, "value" => raw_value} <-
           Regex.named_captures(@raw_price_pattern, raw_shipping_price),
         currency when currency != nil <- currency_from_symbol(raw_currency),
         {:ok, money} <- Money.parse(raw_value, currency) do
      {:ok, money}
    else
      _ -> :error
    end
  end

  @spec currency_from_symbol(String.t()) :: atom() | nil
  defp currency_from_symbol("€"), do: :EUR
  defp currency_from_symbol("CA$"), do: :CAD
  defp currency_from_symbol("SEK"), do: :SEK
  defp currency_from_symbol("$"), do: :USD
  defp currency_from_symbol("R$"), do: :BRL
  defp currency_from_symbol("£"), do: :GBP
  defp currency_from_symbol("¥"), do: :JPY
  defp currency_from_symbol("A$"), do: :AUD
  defp currency_from_symbol("MX$"), do: :MXN
  defp currency_from_symbol("CHF"), do: :CHF
  defp currency_from_symbol("NZ$"), do: :NZD
  defp currency_from_symbol("R"), do: :ZAR
  defp currency_from_symbol("DKK"), do: :DKK

  defp currency_from_symbol(symbol) when is_binary(symbol) do
    with {:ok, existing_atom} <- SafeAtom.maybe_string_to_existing_atom(symbol),
         %{} <- Money.Currency.get(existing_atom) do
      existing_atom
    else
      _ -> nil
    end
  end
end

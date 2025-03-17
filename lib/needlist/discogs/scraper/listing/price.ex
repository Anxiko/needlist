defmodule Needlist.Discogs.Scraper.Listing.Price do
  @moduledoc """
  Parse the price information of a listing obtained through the scraper
  """

  @raw_price_pattern ~r/\+?(?P<currency>[^\d]+)(?P<value>[\d\.,]+)$/
  @free_shipping "+no extra shipping"
  @unspecified_shipping "+"

  import Needlist.Discogs.Scraper.Listing.Parsing, only: [node_outer_text: 1, find_node_by_selector: 2]

  @keys [:base, :shipping, :total]
  @enforce_keys @keys

  defstruct @keys

  @type t() :: %__MODULE__{
          base: Money.t(),
          shipping: Money.t() | nil,
          total: Money.t() | nil
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
      {step, {:error, details}} -> {:error, {step, details}}
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

  @spec parse_shipping_price(Floki.html_node()) :: {:ok, Money.t() | nil} | {:error, any()}
  defp parse_shipping_price(item_price) do
    with {:ok, shipping_price_node} <- find_node_by_selector(item_price, ".item_shipping") do
      shipping_price_node
      |> node_outer_text()
      |> parse_raw_price()
    end
  end

  @spec parse_total_price(Floki.html_node()) :: {:ok, Money.t() | nil} | {:error, any()}
  defp parse_total_price(item_price) do
    with {:ok, total_price_node} <- find_node_by_selector(item_price, ".converted_price"),
         raw_total_price = node_outer_text(total_price_node),
         # Note that an unspecified shipping is not valid for a total price, so we ensure that we are getting %Money{} here
         {:ok, %Money{} = money} <- parse_raw_price(raw_total_price) do
      {:ok, money}
    else
      # When the listing doesn't ship to our location, we don't get a total price at all
      {:error, {:not_found, _}} -> {:ok, nil}
      error -> error
    end
  end

  @spec parse_raw_price(String.t()) :: {:ok, Money.t()} | {:ok, nil} | {:error, any()}
  defp parse_raw_price(@free_shipping), do: {:ok, Money.new(0)}
  # Shipping is sometimes deliberately present but left unspecified
  defp parse_raw_price(@unspecified_shipping), do: {:ok, nil}

  defp parse_raw_price(raw_shipping_price) do
    raw_shipping_price = String.trim(raw_shipping_price)

    with {_, %{"currency" => raw_currency, "value" => raw_value}} <-
           {:regex, Regex.named_captures(@raw_price_pattern, raw_shipping_price)},
         {_, currency} when currency != nil <- {:currency, currency_from_symbol(raw_currency)},
         {_, {:ok, money}} <- {:money, Money.parse(raw_value, currency)} do
      {:ok, money}
    else
      {:regex, nil} -> {:error, {:raw_price_pattern, raw_shipping_price}}
      {:currency, nil} -> {:error, {:currency, raw_shipping_price}}
      {:money, :error} -> {:error, {:money_parsing, raw_shipping_price}}
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
  defp currency_from_symbol(_), do: nil
end

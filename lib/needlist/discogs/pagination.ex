defmodule Needlist.Discogs.Pagination do
  alias Needlist.Discogs.Pagination.Urls

  import Needlist.Discogs.Guards, only: [is_pos_integer: 1, is_non_neg_integer: 1]

  @keys [:page, :pages, :per_page, :items, :urls]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          page: pos_integer(),
          pages: pos_integer(),
          per_page: pos_integer(),
          items: non_neg_integer(),
          urls: Urls.t()
        }

  @spec parse(map()) :: {:ok, t()} | :error
  def parse(%{
        "page" => page,
        "pages" => pages,
        "per_page" => per_page,
        "items" => items,
        "urls" => urls
      })
      when is_pos_integer(page) and is_pos_integer(pages) and is_pos_integer(per_page) and
             is_non_neg_integer(items) do
    case Urls.parse(urls) do
      {:ok, urls} ->
        {:ok, %__MODULE__{page: page, pages: pages, per_page: per_page, items: items, urls: urls}}

      :error ->
        :error
    end
  end

  def parse(_), do: :error
end

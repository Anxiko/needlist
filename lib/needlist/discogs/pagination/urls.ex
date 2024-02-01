defmodule Needlist.Discogs.Pagination.Urls do
  @moduledoc """
  Next and last URLs included in a paginated Discogs API response
  """

  @keys [:first, :last, :prev, :next]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          first: String.t() | nil,
          last: String.t() | nil,
          prev: String.t() | nil,
          next: String.t() | nil
        }

  @spec parse(map()) :: {:ok, t()} | :error
  def parse(%{} = urls) do
    with {:ok, first} <- get_url_if_present(urls, "first"),
         {:ok, last} <- get_url_if_present(urls, "last"),
         {:ok, prev} <- get_url_if_present(urls, "prev"),
         {:ok, next} <- get_url_if_present(urls, "next") do
      {:ok, %__MODULE__{first: first, last: last, prev: prev, next: next}}
    end
  end

  def parse(_), do: :error

  @spec get_url_if_present(map(), String.t()) :: {:ok, String.t() | nil} | :error
  defp get_url_if_present(raw_map, string_key) do
    case Map.fetch(raw_map, string_key) do
      {:ok, url} when is_binary(url) -> {:ok, url}
      {:ok, _invalid_url} -> :error
      :error -> {:ok, nil}
    end
  end
end

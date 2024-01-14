defmodule Needlist.Discogs.Parsing do
  @moduledoc """
  Shared parsing functionality for Discogs API
  """

  @spec parse_many([map()], (map -> item)) :: {:ok, [item]} | :error when item: var
  def parse_many(raw_items, parse_one) do
    raw_items
    |> Stream.map(parse_one)
    |> Enum.reduce_while([], fn
      {:ok, item}, acc -> {:cont, [item | acc]}
      :error, _acc -> {:halt, :error}
    end)
    |> case do
      items when is_list(items) -> {:ok, Enum.reverse(items)}
      :error -> :error
    end
  end

  @spec empty_to_nil(String.t() | nil) :: String.t() | nil
  def empty_to_nil(nil), do: nil

  def empty_to_nil(s) when is_binary(s) do
    case String.trim(s) do
      "" -> nil
      trimmed_string -> trimmed_string
    end
  end
end

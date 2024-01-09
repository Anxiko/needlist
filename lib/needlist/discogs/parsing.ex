defmodule Needlist.Discogs.Parsing do
  @spec parse_many([map()], (map -> item)) :: {:ok, [item]} | :error when item: term
  def parse_many(raw_items, parse_one) do
    raw_items
    |> Stream.map(parse_one)
    |> Enum.reduce_while([], fn
      {:ok, item}, acc -> {:cont, [item | acc]}
      :error, _acc -> {:halt, :error}
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      :error -> :error
    end
  end
end

defmodule MapUtils do
  @moduledoc """
  Small utility functions to manipulate maps
  """

  @doc """
  Rename an existing entry in a map, swapping the old key for a new one, only if it exists.
  If an entry with the new key was already present, it will be overwritten
  """
  @spec rename_existing(map(), key, key) :: map() when key: var
  def rename_existing(map, old_key, new_key) do
    case Map.fetch(map, old_key) do
      {:ok, value} ->
        map
        |> Map.delete(old_key)
        |> Map.put(new_key, value)

      :error ->
        map
    end
  end
end

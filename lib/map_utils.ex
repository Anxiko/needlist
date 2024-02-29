defmodule MapUtils do
  @moduledoc """
  Small utility functions to manipulate maps
  """

  @not_serializable_atoms [nil, true, false]

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

  @doc """
  Converts the atoms in a map to strings. `nil`, `true` and `false` are preserved as-is.
  Conversion of keys and values can be requested separately.
  The conversion is shallow, nested maps won't be converted.
  """
  @spec atoms_as_strings(map(), Keyword.t()) :: map()
  @spec atoms_as_strings(map()) :: map()
  def atoms_as_strings(map, opts \\ [keys: true, values: true]) do
    keys = !!Keyword.get(opts, :keys, false)
    values = !!Keyword.get(opts, :values, false)

    Map.new(map, fn {k, v} ->
      {maybe_convert(k, keys), maybe_convert(v, values)}
    end)
  end

  defguardp is_serializable_atom(atom) when is_atom(atom) and atom not in @not_serializable_atoms

  @spec maybe_convert(any(), boolean()) :: any()
  defp maybe_convert(atom, true) when is_serializable_atom(atom), do: Atom.to_string(atom)
  defp maybe_convert(value, _), do: value
end

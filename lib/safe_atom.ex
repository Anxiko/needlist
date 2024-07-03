defmodule SafeAtom do
  @moduledoc """
  Module for converting a string to an existing atom, without raising if the atom does not exist
  """

  alias Nullables.Fallible

  @spec maybe_string_to_existing_atom(String.t()) :: Fallible.fallible(atom())
  def maybe_string_to_existing_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    ArgumentError -> :error
  end
end

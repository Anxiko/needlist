defmodule AtomEnum do
  @moduledoc """
  Macro for implementing a type based on an enum of atoms.
  """
  defmacro __using__(values: values) do
    quote bind_quoted: [values: values] do
      @type t :: unquote(Enum.reduce(values, fn e, acc -> {:|, [], [e, acc]} end))

      def values do
        unquote(values)
      end

      @spec cast(String.t() | atom()) :: {:ok, t()} | :error
      def cast(value) when is_binary(value) do
        value
        |> String.to_existing_atom()
        |> cast()
      rescue
        ArgumentError -> :error
      end

      def cast(atom) when atom in unquote(values) do
        {:ok, atom}
      end

      def cast(atom) when is_atom(atom), do: :error

      for value <- values do
        def unquote(value)() do
          unquote(value)
        end
      end
    end
  end
end

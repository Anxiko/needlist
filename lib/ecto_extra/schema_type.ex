defmodule EctoExtra.SchemaType do
  defmacro __using__(schema: schema) do
    quote bind_quoted: [schema: schema] do
      use Ecto.Type

      def type, do: :map

      @spec cast(map()) :: {:ok, term} | {:error, keyword()}
      def cast(data) do
        unquote(schema).new()
        |> unquote(schema).changeset(data)
        |> Ecto.Changeset.apply_action(:cast)
        |> case do
          {:ok, valid_data} -> {:ok, valid_data}
          {:error, %Ecto.Changeset{errors: errors}} -> {:error, errors} |> IO.inspect(label: "Errors")
        end
      end

      def load(data) when is_map(data) do
        data = Enum.map(data, fn {k, v} -> {String.to_existing_atom(k), v} end)
        {:ok, struct!(unquote(schema), data)}
      end

      def dump(%unquote(schema){} = data) do
        {:ok, Map.from_struct(data)}
      end

      def dump(_), do: :error
    end
  end
end

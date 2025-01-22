defmodule EctoExtra.DumpableSchema.Embeds do
  @spec dump_embed_field(map :: map(), key :: atom(), fun :: (any() -> any())) :: map()
  @spec dump_embed_field(map :: map(), key :: atom()) :: map()
  def dump_embed_field(map, key, fun \\ &EctoExtra.DumpableSchema.dump/1) do
    Map.update!(map, key, fn
      nil -> nil
      embed when is_struct(embed) -> fun.(embed)
      embeds when is_list(embeds) -> Enum.map(embeds, fun)
    end)
  end

  @spec dump_embed_fields(map :: map(), fields :: [atom() | {atom(), (any() -> any())}]) :: map()
  def dump_embed_fields(map, fields) do
    fields
    |> Enum.reduce(map, fn field, map ->
      {key, fun} =
        case field do
          key when is_atom(key) -> {key, &EctoExtra.DumpableSchema.dump/1}
          {key, fun} when is_atom(key) and is_function(fun, 1) -> {key, fun}
        end

      dump_embed_field(map, key, fun)
    end)
  end
end

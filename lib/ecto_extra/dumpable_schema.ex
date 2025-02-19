defprotocol EctoExtra.DumpableSchema do
  @spec dump(schema :: struct()) :: term()
  def dump(schema)
end

defimpl EctoExtra.DumpableSchema, for: Any do
  @spec dump(schema :: struct()) :: map()
  def dump(schema) when is_struct(schema) do
    Map.from_struct(schema)
  end
end

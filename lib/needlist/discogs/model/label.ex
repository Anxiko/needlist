defmodule Needlist.Discogs.Model.Label do
  @keys [:name, :catno, :id, :resource_url]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          name: String.t(),
          catno: String.t(),
          id: integer(),
          resource_url: String.t()
        }

  @spec parse(map()) :: {:ok, t()} | :error
  def parse(%{
        "name" => name,
        "catno" => catno,
        "id" => id,
        "resource_url" => resource_url
      })
      when is_binary(name) and is_binary(catno) and is_integer(id) and is_binary(resource_url) do
    {:ok, %__MODULE__{name: name, catno: catno, id: id, resource_url: resource_url}}
  end

  def parse(_), do: :error
end

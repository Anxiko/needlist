defmodule Needlist.Discogs.Model.Want do
  @moduledoc """
  Contains an entry of a user's needlist
  """

  @keys [:id, :master_id, :title, :year]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          id: integer(),
          master_id: integer(),
          title: String.t(),
          year: integer()
        }

  @spec parse(map()) :: {:ok, Needlist.Discogs.Model.Want.t()} | :error
  def parse(%{
        "id" => id,
        "basic_information" => %{
          "id" => id,
          "master_id" => master_id,
          "title" => title,
          "year" => year
        }
      })
      when is_integer(id) and is_integer(master_id) and is_binary(title) and is_integer(year) do
    {:ok, %__MODULE__{id: id, master_id: master_id, title: title, year: year}}
  end

  def parse(_), do: :error
end

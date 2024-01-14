defmodule Needlist.Discogs.Model.Want do
  @moduledoc """
  Contains an entry of a user's needlist
  """

  import Needlist.Discogs.Parsing, only: [parse_many: 2]

  require Logger
  alias Needlist.Discogs.Model.Artist

  @keys [:id, :master_id, :title, :year, :artists]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          id: integer(),
          master_id: integer(),
          title: String.t(),
          year: integer(),
          artists: [Artist.t()]
        }

  @spec parse(map()) :: {:ok, Needlist.Discogs.Model.Want.t()} | :error
  def parse(%{
        "id" => id,
        "basic_information" => %{
          "id" => id,
          "master_id" => master_id,
          "title" => title,
          "year" => year,
          "artists" => artists
        }
      })
      when is_integer(id) and is_integer(master_id) and is_binary(title) and is_integer(year) and
             is_list(artists) do
    with {:ok, artists} <- parse_many(artists, &Artist.parse/1) do
      {:ok, %__MODULE__{id: id, master_id: master_id, title: title, year: year, artists: artists}}
    end
  end

  def parse(invalid_want) do
    Logger.error("Invalid want: #{inspect(invalid_want)}")
    :error
  end
end

defmodule Needlist.Discogs.Model.Want do
  @moduledoc """
  Contains an entry of a user's needlist
  """

  import Needlist.Discogs.Parsing, only: [parse_many: 2]

  require Logger

  alias Needlist.Discogs.Model.Artist
  alias Needlist.Discogs.Model.Label
  alias Needlist.Discogs.Model.Format

  @keys [:id, :master_id, :title, :year, :artists, :labels, :formats]
  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          id: integer(),
          master_id: integer(),
          title: String.t(),
          year: integer(),
          artists: [Artist.t()],
          labels: [Label.t()],
          formats: [Format.t()]
        }

  @spec parse(map()) :: {:ok, Needlist.Discogs.Model.Want.t()} | :error
  def parse(%{
        "id" => id,
        "basic_information" => %{
          "id" => id,
          "master_id" => master_id,
          "title" => title,
          "year" => year,
          "artists" => artists,
          "labels" => labels,
          "formats" => formats
        }
      })
      when is_integer(id) and is_integer(master_id) and is_binary(title) and is_integer(year) and
             is_list(artists) and is_list(labels) and is_list(formats) do
    with {:ok, artists} <- parse_many(artists, &Artist.parse/1),
         {:ok, labels} <- parse_many(labels, &Label.parse/1),
         {:ok, formats} <- parse_many(formats, &Format.parse/1) do
      {:ok,
       %__MODULE__{
         id: id,
         master_id: master_id,
         title: title,
         year: year,
         artists: artists,
         labels: labels,
         formats: formats
       }}
    end
  end

  def parse(invalid_want) do
    Logger.error("Invalid want: #{inspect(invalid_want)}")
    :error
  end
end

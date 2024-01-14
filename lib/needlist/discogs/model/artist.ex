defmodule Needlist.Discogs.Model.Artist do
  @moduledoc """
  An artist, credited to a release
  """
  require Logger

  import Needlist.Discogs.Parsing, only: [empty_to_nil: 1]

  @keys [:name, :anv, :id, :resource_url]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          name: String.t(),
          anv: String.t() | nil,
          id: integer(),
          resource_url: String.t()
        }

  @spec parse(map()) :: {:ok, t()} | :error
  def parse(%{"name" => name, "anv" => anv, "id" => id, "resource_url" => resource_url})
      when is_binary(name) and is_binary(anv) and is_integer(id) and is_binary(resource_url) do
    {:ok,
     %__MODULE__{
       name: name,
       anv: empty_to_nil(anv),
       id: id,
       resource_url: resource_url
     }}
  end

  def parse(invalid_artist) do
    Logger.error("Invalid artist: #{inspect(invalid_artist)}")
    :error
  end
end

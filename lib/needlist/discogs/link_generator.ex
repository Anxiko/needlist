defmodule Needlist.Discogs.LinkGenerator do
  @moduledoc """
  Generate URLs to Discogs entities from their schemas
  """
  alias Needlist.Repo.Want
  alias Needlist.Repo.Want.Artist

  @base_url :needlist |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:base) |> URI.new!()

  @spec from_artist(want :: Artist.t()) :: String.t()
  def from_artist(%Artist{id: artist_id} = artist) do
    from_artist_id(artist_id, artist |> Artist.display_name())
  end

  @spec from_artist_id(artist_id :: integer(), display_name :: String.t() | nil) :: String.t()
  @spec from_artist_id(artist_id :: integer()) :: String.t()
  def from_artist_id(artist_id, display_name \\ nil) do
    artist_path =
      if display_name != nil do
        "#{artist_id}-#{encode_name(display_name)}"
      else
        "#{artist_id}"
      end

    @base_url
    |> URI.append_path("/artist/#{artist_path}")
    |> URI.to_string()
  end

  @spec from_want(want :: Want.t()) :: String.t()
  def from_want(%Want{id: want_id, basic_information: %Want.BasicInformation{artists: [_ | _] = artists}}) do
    artists_names = Enum.map_join(artists, "-", &Artist.display_name/1)

    from_want_id(want_id, artists_names)
  end

  def from_want(%Want{id: want_id}) do
    from_want_id(want_id)
  end

  @spec from_want_id(want_id :: integer(), artist_names :: String.t() | nil) :: term()
  def from_want_id(want_id, artist_names \\ nil) do
    want_path =
      if artist_names != nil do
        "#{want_id}-#{encode_name(artist_names)}"
      else
        "#{want_id}"
      end

    @base_url
    |> URI.append_path("/release/#{want_path}")
    |> URI.to_string()
  end

  @spec encode_name(raw_string :: String.t()) :: String.t()
  defp encode_name(raw_string) do
    raw_string
    |> String.replace(" ", "-")
    |> URI.encode()
  end
end

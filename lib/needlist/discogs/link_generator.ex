defmodule Needlist.Discogs.LinkGenerator do
  alias Needlist.Repo.Want.Artist

  @base_url :needlist |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:base) |> URI.new!()

  @spec from_artist(want :: Artist.t()) :: String.t()
  def from_artist(%Artist{id: artist_id}) do
    from_artist_id(artist_id)
  end

  @spec from_artist_id(integer()) :: String.t()
  def from_artist_id(artist_id) do
    @base_url
    |> URI.append_path("/artist/#{artist_id}")
    |> URI.to_string()
  end
end

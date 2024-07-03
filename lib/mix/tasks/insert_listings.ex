defmodule Mix.Tasks.InsertListings do
  @moduledoc """
  Scrape a downloaded listings HTML file
  """

  use Mix.Task

  alias Needlist.Repo

  @requirements ["app.start"]

  @filename_pattern ~r"release_listings_(?P<release_id>\d+)\.html$"

  @impl true
  def run([listings_file]) do
    raw_html = File.read!(listings_file)
    release_id = parse_listings_filename(listings_file)

    {:ok, document} = Floki.parse_document(raw_html)

    {:ok, scrapped_listings} = Needlist.Discogs.Scraper.parse(document)
    changesets = Enum.map(scrapped_listings, &Repo.Listing.changeset_from_scrapped(&1, release_id))

    Repo.transaction(fn ->
      Enum.each(changesets, &Repo.insert!/1)
    end)
  end

  def run(args) do
    IO.puts("Invalid args: #{inspect(args)}")
  end

  @spec parse_listings_filename(String.t()) :: integer()
  defp parse_listings_filename(filename) do
    %{"release_id" => release_id} = Regex.named_captures(@filename_pattern, filename)
    release_id |> String.to_integer()
  end
end

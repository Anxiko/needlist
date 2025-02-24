defmodule Mix.Tasks.Listings do
  @moduledoc """
  Scrape the listings of a given release, and store them in the DB.
  """

  use Mix.Task

  import Needlist.Python, only: [scrape_listings: 1]

  require Logger
  alias Needlist.Releases
  alias Needlist.Repo.Listing

  @scrapped_filename_pattern ~r"release_listings_(?P<release_id>\d+)\.html$"

  @requirements ["app.start"]

  @impl Mix.Task
  def run(["download", release_id]) do
    {:ok, raw_document} = scrape_listings(release_id)
    save_to_file(release_id, raw_document)
  end

  def run(["insert", scrapped_file]) do
    raw_document = File.read!(scrapped_file)
    release_id = parse_scrapped_filename(scrapped_file)
    insert_listings(release_id, raw_document)
  end

  def run(["scrape", release_id]), do: scrape(release_id)
  def run([release_id]), do: scrape(release_id)

  def run(args) do
    IO.puts("Invalid args: #{inspect(args)}")
  end

  @spec scrape(integer()) :: :ok
  defp scrape(release_id) do
    {:ok, raw_document} = scrape_listings(release_id)
    insert_listings(release_id, raw_document)
  end

  defp save_to_file(release_id, raw_document) do
    file_path = scrapped_file_path(release_id)
    File.write!(file_path, raw_document)
    Logger.info("Saved listings to #{file_path}")
  end

  @spec insert_listings(integer(), String.t()) :: :ok
  defp insert_listings(release_id, raw_document) do
    {:ok, document} = Floki.parse_document(raw_document)

    {:ok, scrapped_listings} = Needlist.Discogs.Scraper.parse(document)

    listing_params_list =
      Enum.map(scrapped_listings, &Listing.params_from_scrapped(&1, release_id))

    Logger.info("Found #{length(listing_params_list)} listings for #{release_id}")

    {:ok, release} = Releases.get_by_id(release_id)
    {:ok, _want} = Releases.update_active_listings(release, listing_params_list)

    :ok
  end

  @spec scrapped_file_path(integer()) :: String.t()
  defp scrapped_file_path(release_id) do
    ".payloads/release_listings_#{release_id}.html"
  end

  @spec parse_scrapped_filename(String.t()) :: integer()
  defp parse_scrapped_filename(scrapped_filename) do
    %{"release_id" => release_id} = Regex.named_captures(@scrapped_filename_pattern, scrapped_filename)
    String.to_integer(release_id)
  end
end

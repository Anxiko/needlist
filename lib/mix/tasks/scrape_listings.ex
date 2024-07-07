defmodule Mix.Tasks.ScrapeListings do
  @moduledoc """
  Download the listings for a given release, and store them to a file.
  """

  use Mix.Task

  import Needlist.Python, only: [scrape_listings: 1]

  @requirements ["app.start"]

  @impl true
  def run([release_id]) do
    {:ok, raw_html} = scrape_listings(release_id)
    File.write!(".payloads/release_listings_#{release_id}.html", raw_html)
  end

  def run(args) do
    IO.puts("Invalid args: #{inspect(args)}")
  end
end

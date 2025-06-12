defmodule Scheduled do
  @moduledoc """
  Scheduled tasks to be run on fly.io.
  """

  def discogs do
    Application.ensure_all_started(:req)

    Needlist.Users.all()
    |> Enum.each(fn user ->
      IO.puts("Scraping #{user.username}'s wantlist")
      Needlist.Discogs.Scraper.scrape_wantlist(user.username)
      # Sleep to avoid hitting API rate limits
      Process.sleep(1000)
    end)
  end
end

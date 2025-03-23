defmodule Mix.Tasks.Scrape.Wantlist do
  @moduledoc """
  Download a user's entire needlist, and insert the user and their needlist into the DB.
  """

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run([username]) do
    {:ok, _} = Application.ensure_all_started(:req)

    Needlist.Discogs.Scraper.scrape_wantlist(username)
  end

  def run(_) do
    IO.puts("Specify just 1 argument with the username")
  end
end

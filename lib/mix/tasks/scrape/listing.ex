defmodule Mix.Tasks.Scrape.Listing do
  @moduledoc """
  Scrape the listings associated to a release. Releases can be specified by ID, or by a limit on outdated listings.
  """

  use Mix.Task

  require Logger

  alias Nullables.Result

  @requirements ["app.start"]

  @impl true
  def run([release | release_ids]) when release in ["release", "releases"] do
    release_ids
    |> Enum.map(fn release_id ->
      case Integer.parse(release_id) do
        {release_id, ""} -> {:ok, release_id}
        _ -> {:error, release_id}
      end
    end)
    |> Result.try_reduce()
    |> case do
      {:ok, release_ids} ->
        scrape({:release, release_ids})
    end
  end

  def run(["wantlist" | args]) do
    args
    |> OptionParser.parse(strict: [expiration: :string, limit: :integer, expiration: :string])
    |> case do
      {parsed_args, [], []} ->
        parsed_args = Keyword.replace_lazy(parsed_args, :expiration, &Duration.from_iso8601!/1)
        scrape({:outdated, parsed_args})

      {_parsed, _remaining, _invalid} ->
        IO.puts("Invalid args for wantlist: #{inspect(args)}")
    end
  end

  defp scrape(src) do
    %{ok: ok_results, error: error_results} = Needlist.Discogs.Scraper.scrape_listings(src)

    Logger.info("Total processed: #{length(ok_results) + length(error_results)}")
    Logger.info("Processed OK (#{length(ok_results)}): #{inspect(ok_results, charlists: :as_lists)}")
    Logger.warning("Processed error (#{length(error_results)}): #{inspect(error_results, charlists: :as_lists)}")
  end
end

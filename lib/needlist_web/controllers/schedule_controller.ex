defmodule NeedlistWeb.TasksController do
  @moduledoc """
  Controller used to trigger tasks through API requests.
  """

  use NeedlistWeb, :controller

  alias Needlist.Users

  @wantlist_scrape_sleep_ms 1_000
  @listings_scrape_limit 100

  @spec wantlist(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def wantlist(conn, _params) do
    users = Users.all()
    usernames = Enum.map(users, & &1.username)

    Task.async(fn -> scrape_users(usernames) end)

    conn
    |> put_status(:ok)
    |> json(%{
      task: "wantlist",
      status: "started",
      args: %{users: usernames}
    })
  end

  @spec listings(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def listings(conn, _params) do
    Task.async(fn -> scrape_listings() end)

    conn
    |> put_status(:ok)
    |> json(%{
      task: "listings",
      status: "started",
      args: %{}
    })
  end

  defp scrape_users(usernames) do
    Enum.each(usernames, fn username ->
      Needlist.Discogs.Scraper.scrape_wantlist(username)
      # Sleep to avoid hitting API rate limits
      Process.sleep(@wantlist_scrape_sleep_ms)
    end)
  end

  defp scrape_listings() do
    Needlist.Discogs.Scraper.scrape_listings({:outdated, limit: @listings_scrape_limit})
  end
end

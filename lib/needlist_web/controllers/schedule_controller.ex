defmodule NeedlistWeb.ScheduleController do
  @moduledoc """
  Controller used to trigger scheduled tasks.
  """

  use NeedlistWeb, :controller

  alias Needlist.Users

  @user_scrape_sleep_ms 1_000

  @spec run(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def run(conn, _options) do
    users = Users.all()
    usernames = Enum.map(users, & &1.username)

    Task.async(fn -> scrape_users(usernames) end)

    conn
    |> put_status(:ok)
    |> json(%{
      message: "Scheduled tasks have been started.",
      users: usernames
    })
  end

  defp scrape_users(usernames) do
    Enum.each(usernames, fn username ->
      Needlist.Discogs.Scraper.scrape_wantlist(username)
      # Sleep to avoid hitting API rate limits
      Process.sleep(@user_scrape_sleep_ms)
    end)
  end
end

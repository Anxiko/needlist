defmodule Mix.Tasks.DownloadWantlist do
  alias Needlist.Discogs.Api

  use Mix.Task

  @impl true
  def run([username]) do
    {:ok, _} = Application.ensure_all_started(:req)

    {:ok, user} = Api.get_user(username)
    IO.inspect(user)
  end

  def run(_) do
    IO.puts("Specify just 1 argument with the username")
  end
end

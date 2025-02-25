defmodule Mix.Tasks.DownloadWantlist do
  @moduledoc """
  Download a user's entire needlist, and insert the user and their needlist into the DB.
  TODO: instead of inserting to DB, export to file, and move inserting into DB into a new, separate task.
  """

  alias Needlist.Wantlists
  alias Needlist.Repo.Release
  alias Needlist.Repo.Want
  alias Needlist.Discogs.Api
  alias Needlist.Repo
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Pagination.PageInfo
  alias Needlist.Repo.User
  alias Needlist.Repo.Wantlist
  alias Nullables.Result
  use Mix.Task

  @per_page 500

  @requirements ["app.start"]

  @impl true
  def run([username]) do
    {:ok, _} = Application.ensure_all_started(:req)

    {:ok, user} = Api.get_user(username)
    {:ok, wants} = get_needlist(username)

    Repo.transaction(fn ->
      user =
        user
        |> User.changeset()
        |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)

      wants
      |> Enum.map(fn want ->
        {:ok, want} = Release.from_want(want)
        want
      end)
      |> Enum.each(&Repo.insert(&1, on_conflict: :replace_all, conflict_target: :id))

      release_ids = MapSet.new(wants, fn %Want{id: id} -> id end)

      username
      |> Wantlists.by_username()
      |> Enum.filter(fn %Wantlist{release_id: release_id} -> not MapSet.member?(release_ids, release_id) end)
      |> Enum.each(&Repo.delete!(&1))

      wants
      |> Enum.map(fn want ->
        {:ok, want} = Wantlist.from_scrapped_want(want, user.id)
        want
      end)
      |> Enum.each(
        &Repo.insert(&1, on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:user_id, :release_id])
      )
    end)
  end

  def run(_) do
    IO.puts("Specify just 1 argument with the username")
  end

  @spec get_needlist(String.t()) :: Result.result([Want.t()])
  defp get_needlist(username) do
    1
    |> Stream.iterate(&Kernel.+(&1, 1))
    |> Stream.map(&Api.get_user_needlist(username, per_page: @per_page, page: &1))
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, %Pagination{items: items, page_info: page_info}}, {:ok, pages} ->
        pages = [items | pages]

        cont_or_halt = if PageInfo.last_page?(page_info), do: :halt, else: :cont
        {cont_or_halt, {:ok, pages}}

      {:error, _} = error, _acc ->
        {:halt, error}
    end)
    |> Result.map(fn pages ->
      pages
      |> Enum.reverse()
      |> Enum.concat()
    end)
  end
end

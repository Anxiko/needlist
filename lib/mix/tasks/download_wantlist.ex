defmodule Mix.Tasks.DownloadWantlist do
  alias Needlist.Repo.Want
  alias Needlist.Discogs.Api
  alias Needlist.Repo
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Pagination.PageInfo
  alias Needlist.Repo.User
  alias Nullables.Result
  use Mix.Task

  @per_page 500

  @requirements ["app.start"]

  @impl true
  def run([username]) do
    {:ok, _} = Application.ensure_all_started(:req)

    {:ok, user} = Api.get_user(username)
    {:ok, needlist} = get_needlist(username)

    needlist
    |> Enum.group_by(fn %Want{id: id} -> id end)
    |> Map.filter(fn {_id, wants} -> length(wants) > 1 end)
    |> IO.inspect(label: "Repeated wants")

    user = %{user | wants: needlist}

    user
    |> User.changeset()
    |> Repo.insert_or_update!()
  end

  def run(_) do
    IO.puts("Specify just 1 argument with the username")
  end

  @spec get_needlist(String.t()) :: Result.result([Want.t()])
  defp get_needlist(username) do
    1
    |> Stream.iterate(&Kernel.+(&1, 1))
    |> Stream.map(&Api.get_user_needlist_repo(username, per_page: @per_page, page: &1))
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

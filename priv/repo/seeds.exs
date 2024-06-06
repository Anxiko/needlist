# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Needlist.Repo.insert!(%Needlist.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Needlist.Repo
alias Needlist.Repo.Want
alias Needlist.Repo.Pagination

{:ok, %Pagination{items: items}} =
  "priv/repo/fixtures/wants.json"
  |> File.read!()
  |> Jason.decode!()
  |> then(&Pagination.parse(&1, :wants, Want))

Enum.each(items, &Repo.insert!/1)

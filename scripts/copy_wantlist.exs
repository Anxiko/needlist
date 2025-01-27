alias Needlist.Repo.Wantlist
alias Needlist.Repo
alias Needlist.Wants
alias Nullables.Result

defmodule CopyWantlist do
end

wants = Wants.all()

wants
|> Enum.each(fn want ->
  want
  |> Repo.Release.from_want()
  |> Result.unwrap!()
  |> Repo.insert!(conflict_target: [:id], on_conflict: {:replace_all_except, [:inserted_at]})
end)

wants
|> Enum.flat_map(fn want ->
  want
  |> Wantlist.from_want()
  |> Result.unwrap!()
end)
|> Enum.each(
  &Repo.insert!(&1, conflict_target: [:user_id, :release_id], on_conflict: {:replace_all_except, [:inserted_at]})
)

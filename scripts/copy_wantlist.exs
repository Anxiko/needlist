alias Needlist.Repo
alias Needlist.Wants
alias Nullables.Result

defmodule CopyWantlist do
end

wants =
  Wants.all()
  # |> Enum.map(&EctoExtra.DumpableSchema.dump/1)
  |> Enum.filter(fn %{listings: listings} -> not Enum.empty?(listings) end)

wants
|> Enum.map(fn want ->
  want
  |> Repo.Release.from_want()
  |> Result.unwrap!()
  |> Repo.insert!(conflict_target: [:id], on_conflict: {:replace_all_except, [:inserted_at]})
end)

defmodule Needlist.Repo.Migrations.AddTimestampsListings do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      timestamps(default: fragment("timezone('utc', now())"))
    end
  end
end

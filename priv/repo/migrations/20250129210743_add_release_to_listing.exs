defmodule Needlist.Repo.Migrations.AddReleaseToListing do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :release_id, references(:releases), null: true
    end
  end
end

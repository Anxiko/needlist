defmodule Needlist.Repo.Migrations.AddActiveToListings do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :active, :boolean, null: false, default: true
    end
  end
end

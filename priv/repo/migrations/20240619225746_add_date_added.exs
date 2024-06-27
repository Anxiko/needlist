defmodule Needlist.Repo.Migrations.AddDateAdded do
  use Ecto.Migration

  def change do
    alter table(:wants) do
      add :date_added, :utc_datetime, null: false
    end
  end
end

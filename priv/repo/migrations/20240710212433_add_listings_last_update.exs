defmodule Needlist.Repo.Migrations.AddListingsLastUpdate do
  use Ecto.Migration

  def change do
    alter table(:wants) do
      add :listings_last_updated, :utc_datetime, null: true
    end
  end
end

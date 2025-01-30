defmodule Needlist.Repo.Migrations.AddListingsLastUpdateToRelease do
  use Ecto.Migration

  def change do
    alter table(:releases) do
      add :listings_last_updated, :utc_datetime, null: true
    end
  end
end

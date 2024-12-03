defmodule Needlist.Repo.Migrations.CreateWantlist do
  use Ecto.Migration

  def change do
    create table(:wantlist, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :release_id, references(:releases), primary_key: true
      add :notes, :text, null: true
      add :date_added, :utc_datetime, null: false

      timestamps()
    end
  end
end

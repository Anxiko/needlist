defmodule Needlist.Repo.Migrations.AddOauthToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :oauth, :map, null: true
    end
  end
end

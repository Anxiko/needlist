defmodule Needlist.Repo.Migrations.AddUserToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :user_id, references(:users), null: true
    end
  end
end

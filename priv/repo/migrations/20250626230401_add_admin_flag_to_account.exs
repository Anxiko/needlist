defmodule Needlist.Repo.Migrations.AddAdminFlagToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :admin, :boolean, default: false, null: false
    end
  end
end

defmodule Needlist.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :type, :string, null: false
      add :status, :string, null: false
      add :args, :map, null: false
      add :finished_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end

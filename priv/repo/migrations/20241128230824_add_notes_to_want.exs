defmodule Needlist.Repo.Migrations.AddNotesToWant do
  use Ecto.Migration

  def change do
    alter table(:wants) do
      add :notes, :text, null: true
    end
  end
end

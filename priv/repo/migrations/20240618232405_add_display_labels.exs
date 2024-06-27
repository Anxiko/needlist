defmodule Needlist.Repo.Migrations.AddDisplayLabels do
  use Ecto.Migration

  def change do
    alter table(:wants) do
      add :display_labels, :text, null: false
    end
  end
end

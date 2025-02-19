defmodule Needlist.Repo.Migrations.AddSortingFieldsToRelease do
  use Ecto.Migration

  def change do
    alter table(:releases) do
      add :display_artists, :text, null: false, default: ""
      add :display_labels, :text, null: false, default: ""
    end
  end
end

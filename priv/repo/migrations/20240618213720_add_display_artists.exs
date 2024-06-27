defmodule Needlist.Repo.Migrations.AddDisplayArtists do
  use Ecto.Migration

  def change do
    alter table(:wants) do
      add :display_artists, :text, null: false
    end
  end
end

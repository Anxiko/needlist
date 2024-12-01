defmodule Needlist.Repo.Migrations.CreateReleases do
  use Ecto.Migration

  def change do
    create table(:releases) do
      add :master_id, :id, null: false
      add :title, :text, null: false
      add :year, :integer, null: true

      # Apparently it's better to type many embeds as a map, instead as some sort of array
      # See: https://hexdocs.pm/ecto/embedded-schemas.html
      add :artists, :map, null: true
      add :labels, :map, null: true
      add :formats, :map, null: true
    end
  end
end

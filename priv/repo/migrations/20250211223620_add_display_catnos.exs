defmodule Needlist.Repo.Migrations.AddDisplayCatnos do
  use Ecto.Migration

  def change do
    alter table(:releases) do
      add :display_catnos, :text, null: false, default: ""
    end
  end
end

defmodule Needlist.Repo.Migrations.AddRatingToWantlist do
  use Ecto.Migration

  def change do
    alter table(:wantlist) do
      add :rating, :integer, null: true
    end
  end
end

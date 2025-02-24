defmodule Needlist.Repo.Migrations.RemoveWants do
  use Ecto.Migration

  def change do
    drop constraint(:listings, "listings_want_id_fkey")

    alter table(:listings) do
      remove :want_id
    end

    drop table(:user_wantlist)
    drop table(:wants)
  end
end

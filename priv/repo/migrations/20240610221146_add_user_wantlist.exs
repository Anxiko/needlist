defmodule Needlist.Repo.Migrations.AddUserWantlist do
  use Ecto.Migration

  def change do
    create table(:user_wantlist, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :wantlist_id, references(:wants), primary_key: true
    end
  end
end

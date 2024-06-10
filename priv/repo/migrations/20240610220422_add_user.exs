defmodule Needlist.Repo.Migrations.AddUser do
  use Ecto.Migration

  def change do
    create table("users") do
      add :username, :string, nil: false
    end
  end
end

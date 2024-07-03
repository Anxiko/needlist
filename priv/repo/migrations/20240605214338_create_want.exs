defmodule Needlist.Repo.Migrations.CreateWant do
  use Ecto.Migration

  def change do
    create table("wants") do
      add :basic_information, :map, null: false
    end
  end
end

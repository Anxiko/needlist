defmodule Needlist.Repo.Migrations.MakeSleeveConditionNullable do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE listings ALTER COLUMN sleeve_condition DROP NOT NULL",
      "ALTER TABLE listings ALTER COLUMN sleeve_condition ADD NOT NULL"
    )
  end
end

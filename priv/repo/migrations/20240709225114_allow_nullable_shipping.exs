defmodule Needlist.Repo.Migrations.AllowNullableShipping do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE listings ALTER COLUMN shipping_price DROP NOT NULL",
      "ALTER TABLE listings ALTER COLUMN shipping_price ADD NOT NULL"
    )
  end
end

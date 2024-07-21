defmodule Needlist.Repo.Migrations.ListingTotalPriceNullable do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE listings ALTER COLUMN total_price DROP NOT NULL",
      "ALTER TABLE listings ALTER COLUMN total_price ADD NOT NULL"
    )
  end
end

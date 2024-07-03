defmodule Needlist.Repo.Migrations.CreateListings do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :want_id, references(:wants), null: false
      add :media_condition, :text, null: false
      add :sleeve_condition, :text, null: false
      add :base_price, :money_with_currency, null: false
      add :shipping_price, :money_with_currency, null: false
      add :total_price, :money_with_currency, null: false
    end
  end
end

defmodule Needlist.Types.QueryOptions.SortKey do
  @moduledoc """
  Keys to order by on an needlist query.
  """

  @values [:label, :artist, :title, :catno, :format, :rating, :added, :year, :min_price, :avg_price, :max_price, :notes]

  use AtomEnum, values: @values
end

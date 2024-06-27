defmodule Needlist.Discogs.Api.Types.SortKey do
  @moduledoc """
  Keys to order by on an needlist query.
  """

  @values [:label, :artist, :title, :catno, :format, :rating, :added, :year]

  use AtomEnum, values: @values
end

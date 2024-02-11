defmodule Needlist.Discogs.Api.Types.SortKey do
  @values [:label, :artist, :title, :catno, :format, :rating, :added, :year]

  use AtomEnum, values: @values
end

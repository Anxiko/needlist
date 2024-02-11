defmodule Needlist.Discogs.Api.Types.SortOrder do
  @values [:asc, :desc]

  use AtomEnum, values: @values
end

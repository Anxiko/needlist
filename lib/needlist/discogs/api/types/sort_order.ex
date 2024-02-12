defmodule Needlist.Discogs.Api.Types.SortOrder do
  @values [:asc, :desc]

  use AtomEnum, values: @values

  @spec inverse(t()) :: t()
  def inverse(:asc), do: :desc
  def inverse(:desc), do: :asc
end

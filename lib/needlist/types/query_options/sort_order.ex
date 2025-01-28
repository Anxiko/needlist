defmodule Needlist.Types.QueryOptions.SortOrder do
  @moduledoc """
  Order directions on a sorted query.
  """

  @values [:asc, :desc]

  use AtomEnum, values: @values

  @spec inverse(t()) :: t()
  def inverse(:asc), do: :desc
  def inverse(:desc), do: :asc
end

defmodule Needlist.Types.QueryOptions.SortOrder do
  @moduledoc """
  Order directions on a sorted query.
  """

  @values [:asc, :desc]

  use AtomEnum, values: @values

  @spec inverse(t()) :: t()
  def inverse(:asc), do: :desc
  def inverse(:desc), do: :asc

  @spec nulls_last(t()) :: :asc_nulls_last | :desc_nulls_last
  def nulls_last(:asc), do: :asc_nulls_last
  def nulls_last(:desc), do: :desc_nulls_last
end

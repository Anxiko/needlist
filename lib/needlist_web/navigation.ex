defmodule NeedlistWeb.Navigation do
  alias NeedlistWeb.Navigation.PageEntry

  import Needlist.Guards, only: [is_pos_integer: 1]

  @type entry() :: PageEntry.t() | :ellipsis

  @spec entries(pos_integer(), pos_integer()) :: [entry()]
  def entries(current, total)
      when is_pos_integer(current) and is_pos_integer(total) and current <= total do
    entries_before(current) ++ [PageEntry.new(current, :active)] ++ entries_after(current, total)
  end

  @spec entries_before(pos_integer()) :: [entry()]
  defp entries_before(1), do: [PageEntry.new(:prev, :disabled)]
  defp entries_before(2), do: [PageEntry.new(:prev), PageEntry.new(1)]

  defp entries_before(current) when current >= 3,
    do: [PageEntry.new(:prev), PageEntry.new(1), :ellipsis]

  @spec entries_after(pos_integer(), pos_integer()) :: [entry()]
  defp entries_after(total, total), do: [PageEntry.new(:next, :disabled)]

  defp entries_after(current, total) when current + 1 == total,
    do: [PageEntry.new(total), PageEntry.new(:next)]

  defp entries_after(current, total) when total - current >= 2,
    do: [PageEntry.new(current + 1), :ellipsis, PageEntry.new(:next)]
end

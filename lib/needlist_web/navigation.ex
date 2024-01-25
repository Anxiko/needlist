defmodule NeedlistWeb.Navigation do
  alias NeedlistWeb.Navigation.PageEntry

  import Needlist.Guards, only: [is_pos_integer: 1]

  @type entry() :: PageEntry.t() | :ellipsis

  @spec entries(pos_integer(), pos_integer()) :: [entry()]
  def entries(current, total)
      when is_pos_integer(current) and is_pos_integer(total) and current <= total do
    entries_before(current) ++
      [PageEntry.absolute(current, :current)] ++
      entries_after(current, total)
  end

  @spec entries_before(current :: pos_integer()) :: [entry()]
  defp entries_before(1 = current), do: [PageEntry.relative(:prev, current, :disabled)]

  defp entries_before(2 = current),
    do: [PageEntry.relative(:prev, current), PageEntry.absolute(1)]

  defp entries_before(current) when current >= 3,
    do: [PageEntry.relative(:prev, current), PageEntry.absolute(1), :ellipsis, PageEntry.absolute(current - 1)]

  @spec entries_after(current :: pos_integer(), total :: pos_integer()) :: [entry()]
  defp entries_after(total = current, total), do: [PageEntry.relative(:next, current, :disabled)]

  defp entries_after(current, total) when current + 1 == total,
    do: [PageEntry.absolute(total), PageEntry.relative(:next, current)]

  defp entries_after(current, total) when total - current >= 2,
    do: [PageEntry.absolute(current + 1), :ellipsis, PageEntry.absolute(total), PageEntry.relative(:next, current)]
end

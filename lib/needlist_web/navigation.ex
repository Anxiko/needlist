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
  defp entries_before(current) do
    [
      PageEntry.relative(:prev, current, if(current > 1, do: :active, else: :disabled)) | pages_between(1, current - 1)
    ]
  end

  @spec entries_after(current :: pos_integer(), total :: pos_integer()) :: [entry()]
  defp entries_after(current, total) do
    pages_between(current + 1, total) ++
      [PageEntry.relative(:next, current, if(current < total, do: :active, else: :disabled))]
  end

  @spec pages_between(range_start :: integer(), range_end :: integer()) :: [entry()]
  defp pages_between(range_start, range_end) when range_start > range_end, do: []

  defp pages_between(range_start, range_end) do
    [
      {range_end >= range_start, PageEntry.absolute(range_start)},
      {range_end - range_start >= 2, :ellipsis},
      {range_end > range_start, PageEntry.absolute(range_end)}
    ]
    |> filter_entries()
  end

  defp filter_entries(entries) do
    for {true, entry} <- entries, do: entry
  end
end

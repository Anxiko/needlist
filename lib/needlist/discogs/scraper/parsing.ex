defmodule Needlist.Discogs.Scraper.Parsing do
  @moduledoc false

  @spec node_outer_text(Floki.html_tag()) :: String.t()
  def node_outer_text({_tag, _attrs, children}) do
    children
    |> Enum.filter(&is_binary/1)
    |> Enum.map_join(&String.trim/1)
  end
end

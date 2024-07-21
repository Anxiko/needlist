defmodule Needlist.Discogs.Scraper.Parsing do
  @moduledoc false

  @spec find_node_by_selector(Floki.html_node() | Floki.html_tree(), String.t()) ::
          {:ok, Floki.html_node()} | {:error, any()}
  def find_node_by_selector(html, selector) do
    case Floki.find(html, selector) do
      [found] ->
        {:ok, found}

      [] ->
        {:error, {:not_found, selector}}

      [_ | _] = list ->
        {:error, {:too_many_found, length(list), selector}}
    end
  end

  @spec node_outer_text(Floki.html_tag()) :: String.t()
  def node_outer_text({_tag, _attrs, children}) do
    children
    |> Enum.filter(&is_binary/1)
    |> Enum.map_join(&String.trim/1)
  end
end

defmodule NeedlistWeb.NeedlistLive do
  alias Phoenix.LiveView.Socket
  use NeedlistWeb, :live_view

  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Pagination

  import NeedlistWeb.Navigation.Components, only: [pagination: 1]
  require Logger

  @cache :discogs_cache

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:username, username)
      |> assign(:page, 1)
      |> assign_items(username, 1)
    }
  end

  @spec get_items(String.t(), pos_integer()) :: [Want.t()]
  defp get_items(username, page) do
    case Cachex.get!(@cache, {username, page}) do
      nil ->
        case Api.get_user_needlist(username, page) do
          {:ok, %Pagination.Page{data: page_items}} ->
            Cachex.put!(@cache, {username, page}, page_items)
            page_items

          :error ->
            []
        end

      page_items when is_list(page_items) ->
        Logger.debug("Using cached items for #{username} -> #{page}")
        page_items
    end
  end

  @spec assign_items(Socket.t(), String.t(), pos_integer()) :: Socket.t()
  defp assign_items(socket, username, page) do
    items =
      if connected?(socket) do
        get_items(username, page)
      else
        []
      end

    assign(socket, :list, items)
  end

  defp want_artists(assigns) do
    ~H"""
    <span>
      <%= for artist <- @artists do %>
        <.want_artist artist={artist} />
        <%= if artist.join do %>
          <%= artist.join %>
        <% end %>
      <% end %>
    </span>
    """
  end

  defp want_labels(assigns) do
    ~H"""
    <ul>
      <%= for label <- @labels do %>
        <li><.want_label label={label} /></li>
      <% end %>
    </ul>
    """
  end

  defp want_formats(assigns) do
    ~H"""
    <ul>
      <%= for format <- @formats do %>
        <li><.want_format format={format} /></li>
      <% end %>
    </ul>
    """
  end

  defp table_pagination(assigns) do
    url = ~p"/needlist/#{assigns[:username]}"

    assigns =
      assigns
      |> assign(:url, url)

    ~H"""
    <.pagination url={@url} current={1} total={5} />
    """
  end
end

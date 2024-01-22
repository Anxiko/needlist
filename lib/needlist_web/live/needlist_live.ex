defmodule NeedlistWeb.NeedlistLive do
  use NeedlistWeb, :live_view

  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Pagination

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    items =
      if connected?(socket), do: get_items(username), else: []

    {
      :ok,
      socket
      |> assign(:list, items)
      |> assign(:username, username)
    }
  end

  defp get_items(username) do
    username
    |> Api.get_user_needlist()
    |> case do
      {:ok, %Pagination.Page{data: page_items}} -> page_items
      :error -> []
    end
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
end

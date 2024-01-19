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
    <.intersperse :let={label} enum={@labels}>
      <:separator>,</:separator>
      <.want_label label={label} />
    </.intersperse>
    """
  end

  defp want_formats(assigns) do
    ~H"""
    <span>
      <%= for format <- Enum.intersperse(@formats, :sep) do %>
        <%= if format == :sep do %>
          ,
        <% else %>
          <.want_format format={format} />
        <% end %>
      <% end %>
    </span>
    """
  end
end

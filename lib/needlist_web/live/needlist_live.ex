defmodule NeedlistWeb.NeedlistLive do
  use NeedlistWeb, :live_view

  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Pagination

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    items =
      username
      |> Api.get_user_needlist()
      |> case do
        {:ok, %Pagination.Page{data: page_items}} -> page_items
        :error -> []
      end

    {
      :ok,
      socket
      |> assign(:list, items)
      |> assign(:username, username)
    }
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
end

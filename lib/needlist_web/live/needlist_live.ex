defmodule NeedlistWeb.NeedlistLive do
  use NeedlistWeb, :live_view

  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Pagination

  import NeedlistWeb.Components.Discogs

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    items =
      username
      |> Api.get_user_needlist()
      |> case do
        {:ok, %Pagination.Page{data: items}} -> items
        :error -> []
      end

    {
      :ok,
      socket
      |> assign(:list, items)
      |> assign(:username, username)
    }
  end
end

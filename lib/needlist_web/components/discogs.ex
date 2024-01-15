defmodule NeedlistWeb.Components.Discogs do
  @moduledoc """
  HTML components for Discogs
  """

  use Phoenix.Component

  def want(assigns) do
    ~H"""
    <div>
      <%= @item.title %> - <%= @item.title %>
    </div>
    """
  end

  def artist(assigns) do
    ~H"""
    <a
      class="font-medium text-blue-600 dark:text-blue-500 hover:underline"
      href={@artist.resource_url}
    >
      <%= if @artist.anv do %>
        <%= @artist.anv %>*
      <% else %>
        <%= @artist.name %>
      <% end %>
    </a>
    """
  end
end

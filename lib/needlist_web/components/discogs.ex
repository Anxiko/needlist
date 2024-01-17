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

  def want_artist(assigns) do
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

  def want_label(assigns) do
    ~H"""
    <span>
      <a
        class="font-medium text-blue-600 dark:text-blue-500 hover:underline"
        href={@label.resource_url}
      >
        <%= @label.name %>
      </a>
      - <%= @label.catno %>
    </span>
    """
  end

  def want_format(assigns) do
    ~H"""
    <span>
      <%= @format.name %>
      <%= unless Enum.empty?(@format.descriptions) do %>
        <span class="before:content-['('] after:content-[')']">
          <.intersperse :let={description} enum={@format.descriptions}>
            <:separator>,</:separator>
            <%=description%>
          </.intersperse>
        </span>
      <% end %>
    </span>
    """
  end
end

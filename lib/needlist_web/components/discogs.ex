defmodule NeedlistWeb.Components.Discogs do
  @moduledoc """
  HTML components for Discogs
  """

  use Phoenix.Component

  alias Needlist.Discogs.Model, as: DiscogsModels

  def want(assigns) do
    ~H"""
    <div>
      <%= @item.title %> - <%= @item.title %>
    </div>
    """
  end

  attr :artist, DiscogsModels.Artist, required: true

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

  attr :label, DiscogsModels.Label, required: true

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

  attr :format, DiscogsModels.Format, required: true
  attr :rest, :global

  def want_format(assigns) do
    ~H"""
    <span {@rest} class="inline-block">
      <%= @format.name %>
      <%= unless Enum.empty?(@format.descriptions) do %>
        <span>
          (<%= Enum.join(@format.descriptions, ", ") %>)
        </span>
      <% end %>
    </span>
    """
  end
end

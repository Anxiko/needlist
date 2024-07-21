defmodule NeedlistWeb.Components.Discogs do
  @moduledoc """
  HTML components for Discogs
  """

  use Phoenix.Component

  alias Needlist.Repo.Want
  alias Phoenix.LiveView.Rendered

  attr :artist, Want.Artist, required: true

  @spec want_artist(map()) :: Rendered.t()
  def want_artist(assigns) do
    ~H"""
    <a class="font-medium text-blue-600 dark:text-blue-300 hover:underline" href={@artist.resource_url}>
      <%= if @artist.anv do %>
        <%= @artist.anv %>*
      <% else %>
        <%= @artist.name %>
      <% end %>
    </a>
    """
  end

  attr :label, Want.Label, required: true

  @spec want_label(map()) :: Rendered.t()
  def want_label(assigns) do
    ~H"""
    <span>
      <a class="font-medium text-blue-600 dark:text-blue-300 hover:underline" href={@label.resource_url}>
        <%= @label.name %>
      </a>
      - <%= @label.catno %>
    </span>
    """
  end

  attr :format, Want.Format, required: true
  attr :rest, :global

  @spec want_format(map()) :: Rendered.t()
  def want_format(assigns) do
    ~H"""
    <span {@rest}>
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

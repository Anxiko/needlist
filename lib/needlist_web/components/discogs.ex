defmodule NeedlistWeb.Components.Discogs do
  @moduledoc """
  HTML components for Discogs
  """

  use Phoenix.Component

  alias Needlist.Repo.Want
  alias Needlist.Repo.Release
  alias Needlist.Discogs.LinkGenerator

  alias Phoenix.LiveView.Rendered

  import NeedlistWeb.CoreComponents, only: [styled_link: 1]


  attr :notes, :any, required: true

  @spec release_title(map()) :: Rendered.t()
  def release_notes(assigns) do
    ~H"""
    <%= @notes %>
    """
  end

  attr :release, Release, required: true

  @spec release_title(map()) :: Rendered.t()
  def release_title(assigns) do
    assigns = assign(assigns, :href, LinkGenerator.from_release(assigns.release))

    ~H"""
    <.styled_link href={@href}>
      <%= @release.title %>
    </.styled_link>
    """
  end

  attr :artist, Want.Artist, required: true

  @spec want_artist(map()) :: Rendered.t()
  def want_artist(assigns) do
    ~H"""
    <.styled_link href={LinkGenerator.from_artist(@artist)}>
      <%= if @artist.anv do %>
        <%= @artist.anv %>*
      <% else %>
        <%= @artist.name %>
      <% end %>
    </.styled_link>
    """
  end

  attr :label, Want.Label, required: true

  @spec want_label(map()) :: Rendered.t()
  def want_label(assigns) do
    assigns = assign(assigns, :href, LinkGenerator.from_label(assigns.label))

    ~H"""
    <span>
      <.styled_link href={@href}>
        <%= @label.name %>
      </.styled_link>
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

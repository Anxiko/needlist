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

  attr :score, :integer, required: true
  attr :max_score, :integer, default: 5
  attr :click_id, :any, default: nil

  @spec rating(map()) :: Rendered.t()
  def rating(%{score: score, max_score: max_score} = assigns) when 0 <= score and score <= max_score do
    ~H"""
    <div class="flex items-center">
      <.star
        :for={idx <- 1..@max_score//1}
        disabled={idx == @score}
        phx-click="rating"
        phx-value-score={idx}
        phx-value-max-score={@max_score}
        phx-value-click-id={@click_id}
        filled={idx <= @score}
      />
    </div>
    """
  end

  attr :notes, :any, required: true

  @spec release_notes(map()) :: Rendered.t()
  def release_notes(assigns) do
    ~H"""
    {@notes}
    """
  end

  attr :release, Release, required: true

  @spec release_title(map()) :: Rendered.t()
  def release_title(assigns) do
    assigns = assign(assigns, :href, LinkGenerator.from_release(assigns.release))

    ~H"""
    <.styled_link href={@href}>
      {@release.title}
    </.styled_link>
    """
  end

  attr :artist, Want.Artist, required: true

  @spec want_artist(map()) :: Rendered.t()
  def want_artist(assigns) do
    ~H"""
    <.styled_link href={LinkGenerator.from_artist(@artist)}>
      <%= if @artist.anv do %>
        {@artist.anv}*
      <% else %>
        {@artist.name}
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
        {@label.name}
      </.styled_link>
      - {@label.catno}
    </span>
    """
  end

  attr :format, Want.Format, required: true
  attr :rest, :global

  @spec want_format(map()) :: Rendered.t()
  def want_format(assigns) do
    ~H"""
    <span {@rest}>
      {@format.name}
      <%= unless Enum.empty?(@format.descriptions) do %>
        <span>
          ({Enum.join(@format.descriptions, ", ")})
        </span>
      <% end %>
    </span>
    """
  end

  attr :filled, :boolean, required: true
  attr :disabled, :boolean, default: false
  attr :rest, :global

  @spec star(map()) :: Rendered.t()
  defp star(assigns) do
    assigns =
      if assigns.filled do
        assign(assigns, :text, "text-yellow-300")
      else
        assign(assigns, :text, "text-gray-300 dark:text-gray-500")
      end

    ~H"""
    <button {@rest} disabled={@disabled}>
      <svg
        class={["w-4 h-4 min-w-3 ms-1", @text]}
        aria-hidden="true"
        xmlns="http://www.w3.org/2000/svg"
        fill="currentColor"
        viewBox="0 0 22 20"
      >
        <path d="M20.924 7.625a1.523 1.523 0 0 0-1.238-1.044l-5.051-.734-2.259-4.577a1.534 1.534 0 0 0-2.752 0L7.365 5.847l-5.051.734A1.535 1.535 0 0 0 1.463 9.2l3.656 3.563-.863 5.031a1.532 1.532 0 0 0 2.226 1.616L11 17.033l4.518 2.375a1.534 1.534 0 0 0 2.226-1.617l-.863-5.03L20.537 9.2a1.523 1.523 0 0 0 .387-1.575Z" />
      </svg>
    </button>
    """
  end
end

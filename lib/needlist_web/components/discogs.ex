defmodule NeedlistWeb.Components.Discogs do
  @moduledoc """
  HTML components for Discogs
  """

  use Phoenix.Component

  alias Needlist.Repo.Want
  alias Needlist.Repo.Release
  alias Needlist.Discogs.LinkGenerator

  alias Phoenix.LiveView.Rendered

  import NeedlistWeb.CoreComponents, only: [styled_link: 1, button: 1, input: 1]

  attr :score, :integer, required: true
  attr :max_score, :integer, default: 5
  attr :click_id, :any, default: nil
  attr :class, :string, default: nil

  @spec rating(map()) :: Rendered.t()
  def rating(%{score: score, max_score: max_score} = assigns) when 0 <= score and score <= max_score do
    ~H"""
    <div class={["flex items-center", @class]}>
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
  attr :changes, :any, required: true
  attr :release_id, :integer, required: true

  @spec release_notes(map()) :: Rendered.t()
  def release_notes(%{changes: nil} = assigns) do
    ~H"""
    <div class="flex flex-row justify-between gap-1 items-center">
      <%= if @notes == nil do %>
        <span class="italic"> Edit </span>
      <% else %>
        <p>{@notes}</p>
      <% end %>
      <.button phx-click="notes-edit" phx-value-release-id={@release_id} phx-value-notes={if @notes, do: @notes, else: ""}>
        <svg
          class="w-6 h-6 text-gray-800 dark:text-white"
          aria-hidden="true"
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          fill="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            fill-rule="evenodd"
            d="M11.32 6.176H5c-1.105 0-2 .949-2 2.118v10.588C3 20.052 3.895 21 5 21h11c1.105 0 2-.948 2-2.118v-7.75l-3.914 4.144A2.46 2.46 0 0 1 12.81 16l-2.681.568c-1.75.37-3.292-1.263-2.942-3.115l.536-2.839c.097-.512.335-.983.684-1.352l2.914-3.086Z"
            clip-rule="evenodd"
          />
          <path
            fill-rule="evenodd"
            d="M19.846 4.318a2.148 2.148 0 0 0-.437-.692 2.014 2.014 0 0 0-.654-.463 1.92 1.92 0 0 0-1.544 0 2.014 2.014 0 0 0-.654.463l-.546.578 2.852 3.02.546-.579a2.14 2.14 0 0 0 .437-.692 2.244 2.244 0 0 0 0-1.635ZM17.45 8.721 14.597 5.7 9.82 10.76a.54.54 0 0 0-.137.27l-.536 2.84c-.07.37.239.696.588.622l2.682-.567a.492.492 0 0 0 .255-.145l4.778-5.06Z"
            clip-rule="evenodd"
          />
        </svg>
      </.button>
    </div>
    """
  end

  def release_notes(%{changes: {:pending, _notes}} = assigns) do
    ~H"""
    <p class="loader">
      {elem(@changes, 1)}
    </p>
    """
  end

  def release_notes(%{changes: %Ecto.Changeset{}} = assigns) do
    ~H"""
    <.form :let={form} for={@changes} as={:notes} phx-change="notes-validate" phx-submit="notes-submit">
      <div class="flex flex-row justify-between gap-1 items-center">
        <.input type="textarea" field={form[:notes]} />
        <.input type="hidden" field={form[:release_id]} />
        <div class="flex flex-col justify-self-end">
          <.button type="submit" disabled={!@changes.valid? or @changes.changes == %{}}>
            <svg
              class="w-6 h-6 text-gray-800 dark:text-white"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                fill-rule="evenodd"
                d="M5 3a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V7.414A2 2 0 0 0 20.414 6L18 3.586A2 2 0 0 0 16.586 3H5Zm10 11a3 3 0 1 1-6 0 3 3 0 0 1 6 0ZM8 7V5h8v2a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1Z"
                clip-rule="evenodd"
              />
            </svg>
          </.button>
          <.button type="button" phx-click="notes-cancel" phx-value-release-id={@release_id}>
            <svg
              class="w-6 h-6 text-gray-800 dark:text-white"
              aria-hidden="true"
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke="currentColor"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18 17.94 6M18 18 6.06 6"
              />
            </svg>
          </.button>
        </div>
      </div>
    </.form>
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

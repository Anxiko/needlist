defmodule NeedlistWeb.Navigation.Components do
  use NeedlistWeb, :live_component

  alias NeedlistWeb.Navigation
  alias NeedlistWeb.Navigation.PageEntry

  import Needlist.Guards, only: [is_pos_integer: 1]

  attr :page_entry, PageEntry, required: true

  defp inner_page_entry(%{page_entry: %PageEntry{page: {:prev, _page}}} = assigns) do
    ~H"""
    <span class="sr-only">Previous</span>
    <svg
      class="w-3 h-3 rtl:rotate-180"
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 6 10"
    >
      <path
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M5 1 1 5l4 4"
      />
    </svg>
    """
  end

  defp inner_page_entry(%{page_entry: %PageEntry{page: {:next, _page}}} = assigns) do
    ~H"""
    <span class="sr-only">Next</span>
    <svg
      class="w-3 h-3 rtl:rotate-180"
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 6 10"
    >
      <path
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="m1 9 4-4-4-4"
      />
    </svg>
    """
  end

  defp inner_page_entry(%{page_entry: %PageEntry{page: page}} = assigns)
       when is_pos_integer(page) do
    ~H"""
    <%= @page_entry.page %>
    """
  end

  attr :url, :string, required: true
  attr :params, :map, required: true
  attr :page_entry, PageEntry, required: true

  defp nav_to_page_entry(assigns) do
    page = PageEntry.page(assigns[:page_entry])
    params = Map.put(assigns[:params], :page, page)

    assigns =
      assigns
      |> assign(:params, params)

    ~H"""
    <li>
      <.link
        patch={"#{@url}?#{URI.encode_query(@params)}"}
        class="flex items-center justify-center h-10 px-4 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
      >
        <.inner_page_entry page_entry={@page_entry} />
      </.link>
    </li>
    """
  end

  defp nav_ellipsis(assigns) do
    ~H"""
    <li>
      <span class="flex items-center justify-center h-10 px-4 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white">
        ...
      </span>
    </li>
    """
  end

  attr :url, :string, required: true
  attr :params, :map, default: %{}
  attr :current, :integer, required: true
  attr :total, :integer, required: true

  def pagination(assigns) do
    entries = Navigation.entries(assigns[:current], assigns[:total])

    assigns =
      assigns
      |> assign(:entries, entries)

    ~H"""
    <div class="flex justify-center mt-4">
      <nav aria-label="Page navigation example">
        <ul class="flex items-center h-10 -space-x-px text-base">
          <%= for entry <- @entries do %>
            <%= case entry do %>
              <% :ellipsis -> %>
                <.nav_ellipsis />
              <% _ -> %>
                <.nav_to_page_entry page_entry={entry} url={@url} params={@params} />
            <% end %>
          <% end %>
        </ul>
      </nav>
    </div>
    """
  end
end

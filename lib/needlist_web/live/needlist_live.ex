defmodule NeedlistWeb.NeedlistLive do
  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Api.Types.SortKey
  alias Needlist.Discogs.Api.Types.SortOrder
  alias Needlist.Discogs.Pagination.PageInfo
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Want
  alias Needlist.Wants
  alias NeedlistWeb.NeedlistLive.State
  alias Nullables.Fallible
  alias Phoenix.LiveView.Socket
  alias Phoenix.LiveView.JS

  use NeedlistWeb, :live_view

  import NeedlistWeb.Navigation.Components, only: [pagination: 1]

  require Logger

  @initial_sorting_order :asc

  @typep paginated_wants() :: Pagination.t(Want.t())

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:username, username)
      |> assign(:current_page, nil)
      |> assign(:loading_page, nil)
      |> assign(:state, State.default())
    }
  end

  @impl true
  @spec handle_params(map(), any(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(params, _uri, socket) do
    parsed_state =
      params
      |> Fallible.apply_if(max_pages(socket), &Map.put(&1, "max_pages", &2))
      |> State.parse()

    socket =
      socket
      |> assign(:state, parsed_state)
      |> load_page()

    {:noreply, socket}
  end

  @impl true
  def handle_event("sort-by", %{"key" => key}, socket) do
    state = socket.assigns.state

    with {:ok, key} <- SortKey.cast(key),
         changes = create_sorting_changes(state, key),
         {:ok, new_state} <- State.update(state, changes) do
      {:noreply, update_params(socket, new_state)}
    else
      _ ->
        Logger.warning("Invalid state transition from #{inspect(state)} sort-by #{inspect(key)}")
        {:noreply, socket}
    end
  end

  def handle_event("per-page", params, socket) do
    socket =
      case State.update(socket.assigns.state, params) do
        {:ok, new_state} -> update_params(socket, new_state)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_async(
        :table_data,
        {:ok, {requested_needlist_options, _page} = result},
        %Socket{assigns: %{loading_page: requested_needlist_options}} = socket
      ) do
    socket =
      socket
      |> assign(:current_page, result)
      |> assign(:loading_page, nil)

    {:noreply, socket}
  end

  def handle_async(
        :table_data,
        {:ok, {actual, _page}},
        %Socket{
          assigns: %{loading_page: expected}
        } = socket
      )
      when actual != expected do
    Logger.warning("Expected page #{expected}, but got #{actual}, ignoring...")

    {:noreply, socket}
  end

  def handle_async(:table_data, {:ok, result}, socket) do
    Logger.warning("Ignoring unexpected table data (expecting #{socket.assigns[:loading_page]}): #{inspect(result)}")

    {:noreply, socket}
  end

  def handle_async(:table_data, {:exit, reason}, socket) do
    {:noreply, put_flash(socket, :error, "Failed to load data: #{reason}")}
  end

  @spec create_sorting_changes(State.t(), SortKey.t()) :: map()
  defp create_sorting_changes(%State{sort_key: sort_key, sort_order: sort_order}, sort_key) do
    %{sort_order: SortOrder.inverse(sort_order)}
  end

  defp create_sorting_changes(%State{}, sort_key) do
    %{sort_key: sort_key, sort_order: @initial_sorting_order}
  end

  @spec update_params(Socket.t(), State.t()) :: Socket.t()
  defp update_params(socket, new_state) do
    username = socket.assigns.username
    new_params = State.as_params(new_state)

    push_patch(socket, to: ~p"/needlist/#{username}?#{new_params}")
  end

  @spec max_pages(Socket.t()) :: {:ok, pos_integer()} | :error
  defp max_pages(%Socket{assigns: %{current_page: {_, %Pagination{page_info: %PageInfo{pages: pages}}}}}) do
    {:ok, pages}
  end

  defp max_pages(%Socket{}), do: :error

  @spec load_page(Socket.t()) :: Socket.t()
  defp load_page(socket) do
    opts =
      socket.assigns.state
      |> State.as_needlist_options()
      # Sort to ensure that pattern matching works
      |> Enum.sort()

    load_page(socket, opts)
  end

  # Current loaded page matches the requested page
  @spec load_page(Socket.t(), Api.needlist_options()) :: Socket.t()
  defp load_page(
         %Socket{assigns: %{current_page: {requested_needlist_options, _current_page}}} = socket,
         requested_needlist_options
       ) do
    socket
    |> cancel_async(:table_data)
    |> assign(:loading_page, nil)
  end

  # Already in the process of loading the requested page
  defp load_page(%Socket{assigns: %{loading_page: requested_needlist_options}} = socket, requested_needlist_options),
    do: socket

  # Requested page is not loaded nor loading
  defp load_page(socket, requested_needlist_options) do
    username = socket.assigns.username

    socket
    |> cancel_async(:loading_page)
    |> assign(:loading_page, requested_needlist_options)
    |> start_async(:table_data, fn ->
      case fetch_page(username, requested_needlist_options) do
        {:ok, paginated_items} ->
          {requested_needlist_options, paginated_items}
          # {:error, error} -> exit(error)
      end
    end)
  end

  @spec fetch_page(String.t(), Api.needlist_options()) :: {:ok, paginated_wants()} | {:error, any()}
  defp fetch_page(username, needlist_options) do
    needlist = Wants.get_needlist_page(username, needlist_options)
    total = Wants.needlist_size(username)

    page = Keyword.get(needlist_options, :page, 1)
    per_page = Keyword.get(needlist_options, :per_page, 50)

    {:ok, Pagination.from_page(needlist, page, per_page, total)}
  end

  defp want_artists(assigns) do
    ~H"""
    <%= for artist <- @artists do %>
      <.want_artist artist={artist} />
      <%= if artist.join do %>
        <%= artist.join %>
      <% end %>
    <% end %>
    """
  end

  defp want_labels(assigns) do
    ~H"""
    <ul>
      <%= for label <- @labels do %>
        <li><.want_label label={label} /></li>
      <% end %>
    </ul>
    """
  end

  defp want_formats(assigns) do
    ~H"""
    <ul>
      <%= for format <- @formats do %>
        <li><.want_format format={format} /></li>
      <% end %>
    </ul>
    """
  end

  defp want_year(assigns) do
    ~H"""
    <%= if @year != 0 do %>
      <%= @year %>
    <% end %>
    """
  end

  defp want_price(assigns) do
    ~H"""
    <%= @price %>
    """
  end

  defp table_pagination(assigns) do
    url = ~p"/needlist/#{assigns.username}"

    assigns =
      assigns
      |> assign(:url, url)
      |> assign(:current, assigns.current_page.page_info.page)
      |> assign(:total, assigns.current_page.page_info.pages)
      |> assign(:params, State.as_params(assigns.state))

    ~H"""
    <.pagination url={@url} current={@current} total={@total} params={@params} />
    """
  end

  defp header_sorting(%{sort_order: :asc} = assigns),
    do: ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-4 h-4"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5" />
    </svg>
    """

  defp header_sorting(%{sort_order: :desc} = assigns),
    do: ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-4 h-4"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
    </svg>
    """

  defp per_page_selector(assigns) do
    assigns =
      assigns
      |> assign(:form, to_form(%{"per_page" => assigns.selected_per_page}))

    ~H"""
    <.form for={@form} class="max-w-sm mx-auto" phx-change="per-page" id="per-page-form">
      <label for="per-page-input" class="dark:text-white block mb-2 text-sm font-medium text-gray-900">
        Per page items
      </label>
      <.input
        id="per-page-input"
        field={@form[:per_page]}
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
        options={for option <- @per_page_options, do: {option, option}}
        type="select"
      />
    </.form>
    """
  end

  defp table_header(%{column_key: column_key} = assigns) do
    phx_attrs =
      if column_key != nil do
        %{
          "phx-click": "sort-by" |> JS.push() |> JS.toggle_class("rotate-180", to: ".chevron"),
          "phx-value-key": column_key
        }
      else
        %{}
      end

    assigns =
      assigns
      |> assign(:phx_attrs, phx_attrs)

    ~H"""
    <th scope="col" class="px-6 py-3" {@phx_attrs}>
      <span class={"inline-flex items-center font-medium #{@column_key != nil && "cursor-pointer text-blue-600 dark:text-blue-300 hover:underline"}"}>
        <%= @column_name %>
        <%= if @state.sort_key == @column_key and @state.sort_order != nil do %>
          <span class="chevron transition-all duration-300">^</span>
        <% end %>
      </span>
    </th>
    """
  end
end

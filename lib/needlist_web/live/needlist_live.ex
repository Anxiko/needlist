defmodule NeedlistWeb.NeedlistLive do
  use NeedlistWeb, :live_view

  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Pagination
  alias Needlist.Discogs.Model.Want

  alias Nullables.Fallible

  alias Phoenix.LiveView.Socket

  import NeedlistWeb.Navigation.Components, only: [pagination: 1]
  import Needlist.Parser, only: [parse_int: 1, validate_pos_integer: 1]

  require Logger

  @cache :discogs_cache
  @initial_sorting_order :asc

  @typep paginated_wants() :: Pagination.t(Want.t())

  @request_defaults_opts [page: 1, sort_key: :label, sort_order: @initial_sorting_order]

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:username, username)
      |> assign(:current_page, nil)
      |> assign(:loading_page, nil)
      |> assign(:sort_key, nil)
      |> assign(:sort_order, nil)
      |> assign(:page, nil)
    }
  end

  @impl true
  @spec handle_params(map(), any(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_params(params, _uri, socket) do
    parsed_params = parse_params(params) |> IO.inspect(label: "Parsed params")

    socket =
      socket
      |> assign(parsed_params)
      |> load_page()

    {:noreply, socket}
  end

  @impl true
  def handle_event("sort-by", %{"key" => key}, %Socket{assigns: assigns} = socket) do
    key = String.to_existing_atom(key)

    {sort_key, sort_order} =
      case {socket.assigns.sort_key, socket.assigns.sort_order} do
        {^key, sorting} ->
          next_sorting = Api.Types.SortOrder.inverse(sorting)

          if next_sorting != @initial_sorting_order do
            {key, next_sorting}
          else
            {nil, nil}
          end

        _ ->
          {key, @initial_sorting_order}
      end

    params =
      assigns
      |> assign(:sort_key, sort_key)
      |> assign(:sort_order, sort_order)
      |> serialize_params()

    {:noreply, update_params(socket, params)}
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
    socket =
      socket
      |> put_flash(:error, "Failed to load data: #{reason}")

    {:noreply, socket}
  end

  @spec needlist_options(map()) :: Api.needlist_options()
  defp needlist_options(assigns) do
    assigns
    |> Map.take([:page, :sort_order, :sort_key])
    |> Map.filter(fn {_k, v} -> v != nil end)
    |> Keyword.new()
  end

  @spec parse_params(map()) :: Keyword.t()
  defp parse_params(params) do
    page =
      params
      |> Fallible.ok()
      |> Fallible.flat_map_many([
        &Map.fetch(&1, "page"),
        &parse_int/1,
        &validate_pos_integer/1
      ])

    sort_key =
      params
      |> Fallible.ok()
      |> Fallible.flat_map_many([
        &Map.fetch(&1, "sort_key"),
        &Api.Types.SortKey.cast/1
      ])

    sort_order =
      params
      |> Fallible.ok()
      |> Fallible.flat_map_many([
        &Map.fetch(&1, "sort_order"),
        &Api.Types.SortOrder.cast/1
      ])

    [page: page, sort_key: sort_key, sort_order: sort_order]
    |> IO.inspect(label: "Fallible parse params")
    |> Keyword.filter(fn {_k, v} -> Fallible.is_ok?(v) end)
    |> Keyword.new(fn {k, {:ok, v}} -> {k, v} end)
  end

  @spec serialize_params(map()) :: map()
  defp serialize_params(assigns) do
    assigns
    |> Map.take([:page, :sort_key, :sort_order])
    |> Map.filter(fn {_k, v} -> v != nil end)
  end

  @spec update_params(Socket.t(), map()) :: Socket.t()
  defp update_params(socket, new_params) do
    username = socket.assigns.username
    IO.inspect(new_params, label: "New params")

    push_patch(socket, to: ~p"/needlist/#{username}?#{new_params}")
  end

  @spec load_page(Socket.t()) :: Socket.t()
  defp load_page(%Socket{assigns: assigns} = socket) do
    opts =
      assigns
      |> needlist_options()
      |> Keyword.validate!(@request_defaults_opts)
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
    socket
    |> cancel_async(:loading_page)
    |> assign(:loading_page, requested_needlist_options)
    |> start_async(:table_data, fn ->
      fetch_page(socket.assigns.username, requested_needlist_options)
      |> case do
        {:ok, paginated_items} -> {requested_needlist_options, paginated_items}
        {:error, error} -> exit(error)
      end
    end)
  end

  @spec fetch_page(String.t(), Api.needlist_options()) :: {:ok, paginated_wants()} | {:error, any()}
  defp fetch_page(username, needlist_options) do
    case Cachex.get!(@cache, {username, needlist_options}) do
      nil ->
        case Api.get_user_needlist(username, needlist_options) do
          {:ok, %Pagination{} = paginated_items} ->
            Cachex.put!(@cache, {username, needlist_options}, paginated_items)
            {:ok, paginated_items}

          :error ->
            {:error, "Discogs API error"}
        end

      %Pagination{} = paginated_items ->
        Logger.debug("Using cached items for #{username} -> #{inspect(needlist_options)}")
        {:ok, paginated_items}
    end
  end

  defp want_artists(assigns) do
    ~H"""
    <span>
      <%= for artist <- @artists do %>
        <.want_artist artist={artist} />
        <%= if artist.join do %>
          <%= artist.join %>
        <% end %>
      <% end %>
    </span>
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

  defp table_pagination(assigns) do
    url = ~p"/needlist/#{assigns.username}"

    assigns =
      assigns
      |> assign(:url, url)
      |> assign(:current, assigns.current_page.page_info.page)
      |> assign(:total, assigns.current_page.page_info.pages)

    ~H"""
    <.pagination url={@url} current={@current} total={@total} />
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

  defp header_sorting(assigns), do: ~H""
end

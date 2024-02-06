defmodule NeedlistWeb.NeedlistLive do
  alias Needlist.Discogs.Pagination.Page
  alias Phoenix.LiveView.Socket
  use NeedlistWeb, :live_view

  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Pagination
  alias Needlist.Discogs.Model.Want

  import NeedlistWeb.Navigation.Components, only: [pagination: 1]
  import Needlist.Guards

  require Logger

  @cache :discogs_cache
  @initial_sorting_order :asc

  @typep paginated_wants() :: Pagination.Page.t(Want.t())

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:username, username)
      |> assign(:current_page, nil)
      |> assign(:loading_page, nil)
      |> assign(:sort_by, nil)
    }
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = parse_page_param(params)

    socket =
      socket
      |> load_page(page)

    {:noreply, socket}
  end

  @impl true
  def handle_event("sort-by", %{"key" => key}, socket) do
    key = String.to_existing_atom(key)

    sort_by =
      case socket.assigns.sort_by do
        {^key, sorting} ->
          next_sorting = opposite_sorting(sorting)

          if next_sorting != @initial_sorting_order do
            {key, next_sorting}
          else
            nil
          end

        _ ->
          {key, @initial_sorting_order}
      end

    {:noreply, assign(socket, :sort_by, sort_by)}
  end

  @impl true
  def handle_async(
        :table_data,
        {:ok, %Pagination.Page{pagination: %Pagination{page: page}} = paginated_items},
        %Socket{assigns: %{loading_page: page}} = socket
      ) do
    socket =
      socket
      |> assign(:current_page, paginated_items)
      |> assign(:loading_page, nil)

    {:noreply, socket}
  end

  def handle_async(
        :table_data,
        {:ok, %Pagination.Page{pagination: %Pagination{page: actual}}},
        %Socket{
          assigns: %{loading_page: expected}
        } = socket
      )
      when actual != expected do
    Logger.warning("Expected page #{expected}, but got #{actual}, ignoring...")

    {:noreply, socket}
  end

  def handle_async(:table_data, {:ok, paginated_items}, socket) do
    Logger.warning(
      "Ignoring unexpected table data (expecting #{socket.assigns[:loading_page]}): #{inspect(paginated_items)}"
    )

    {:noreply, socket}
  end

  def handle_async(:table_data, {:exit, reason}, socket) do
    socket =
      socket
      |> put_flash(:error, "Failed to load data: #{reason}")

    {:noreply, socket}
  end

  @spec parse_page_param(map()) :: pos_integer()
  defp parse_page_param(params) do
    with {:ok, raw_page} <- Map.fetch(params, "page"),
         {page, ""} when is_pos_integer(page) <- Integer.parse(raw_page) do
      page
    else
      _ -> 1
    end
  end

  @spec load_page(Socket.t(), pos_integer()) :: Socket.t()
  defp load_page(
         %Socket{assigns: %{current_page: %Page{pagination: %Pagination{page: page}}}} = socket,
         page
       ) do
    socket
    |> cancel_async(:table_data)
    |> assign(:loading_page, nil)
  end

  defp load_page(%Socket{assigns: %{loading_page: page}} = socket, page), do: socket

  defp load_page(socket, page) do
    socket
    |> cancel_async(:loading_page)
    |> assign(:loading_page, page)
    |> start_async(:table_data, fn ->
      fetch_page(socket.assigns.username, page)
      |> case do
        {:ok, paginated_items} -> paginated_items
        {:error, error} -> exit(error)
      end
    end)
  end

  @spec fetch_page(String.t(), pos_integer()) :: {:ok, paginated_wants()} | {:error, any()}
  defp fetch_page(username, page) do
    case Cachex.get!(@cache, {username, page}) do
      nil ->
        case Api.get_user_needlist(username, page: page) do
          {:ok, %Pagination.Page{} = paginated_items} ->
            Cachex.put!(@cache, {username, page}, paginated_items)
            {:ok, paginated_items}

          :error ->
            {:error, "Discogs API error"}
        end

      %Pagination.Page{} = paginated_items ->
        Logger.debug("Using cached items for #{username} -> #{page}")
        {:ok, paginated_items}
    end
  end

  defp opposite_sorting(:asc), do: :desc
  defp opposite_sorting(:desc), do: :asc

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
      |> assign(:current, assigns.current_page.pagination.page)
      |> assign(:total, assigns.current_page.pagination.pages)

    ~H"""
    <.pagination url={@url} current={@current} total={@total} />
    """
  end

  defp header_sorting(%{sort_by: {key, :asc}, key: key} = assigns),
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

  defp header_sorting(%{sort_by: {key, :desc}, key: key} = assigns),
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

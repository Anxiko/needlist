defmodule NeedlistWeb.NeedlistLive do
  alias Needlist.Users
  alias Needlist.Oban.Dispatcher, as: ObanDispatcher
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Pagination.PageInfo
  alias Needlist.Repo.Wantlist
  alias Needlist.Types.QueryOptions
  alias Needlist.Types.QueryOptions.SortKey
  alias Needlist.Types.QueryOptions.SortOrder
  alias Needlist.Wantlists
  alias NeedlistWeb.NeedlistLive.State
  alias NeedlistWeb.Components.Notifications.Normal, as: NormalNotification
  alias NeedlistWeb.Toaster
  alias Nullables.Fallible
  alias Phoenix.LiveView.Socket

  use NeedlistWeb, :live_view

  import NeedlistWeb.Navigation.Components, only: [pagination: 1]

  require Logger

  @initial_sorting_order :asc
  @datetime_format Application.compile_env!(:needlist, :datetime_format)
  @update_interval :needlist
                   |> Application.compile_env!(:wantlist_update_interval_seconds)
                   |> Timex.Duration.from_seconds()

  # Just a small offset to ensure the timer expires after we're allowed to request a new wantlist refresh
  @refresh_ready_offset_ms 1

  @typep paginated_wants() :: Pagination.t(Wantlist.t())

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    {
      :ok,
      socket
      |> assign(:username, username)
      |> assign(:current_page, nil)
      |> assign(:loading_page, nil)
      |> assign(:state, State.default())
      |> assign(:pending_wantlist_updates, %{})
      |> assign(:notes_editing, %{})
      |> maybe_assign_timezone()
      |> assign_last_wantlist_update()
      |> maybe_schedule_refresh_ready()
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
  def handle_info(:refresh_ready, socket) do
    {:noreply,
     socket
     |> assign_last_wantlist_update()
     |> maybe_schedule_refresh_ready()}
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

  def handle_event("rating", %{"score" => score, "max-score" => _max_score, "click-id" => click_id}, socket) do
    username = socket.assigns.username
    release_id = String.to_integer(click_id)
    score = String.to_integer(score)

    socket =
      start_async(socket, {:wantlist_update, release_id}, fn ->
        Wantlists.update_wantlist(username, release_id, rating: score)
      end)
      |> update(:pending_wantlist_updates, &Map.put(&1, release_id, score))

    {:noreply, socket}
  end

  def handle_event("notes-edit", %{"release-id" => release_id, "notes" => notes}, socket) do
    release_id = String.to_integer(release_id)
    changeset = notes_changeset(%{release_id: release_id, notes: notes})

    socket =
      update(socket, :notes_editing, &Map.put(&1, release_id, changeset))

    {:noreply, socket}
  end

  def handle_event("notes-cancel", %{"release-id" => release_id}, socket) do
    release_id = String.to_integer(release_id)

    socket = update(socket, :notes_editing, &Map.delete(&1, release_id))

    {:noreply, socket}
  end

  def handle_event("notes-validate", %{"notes" => %{"release_id" => release_id} = params}, socket) do
    release_id = String.to_integer(release_id)

    socket =
      update(
        socket,
        :notes_editing,
        &Map.update!(&1, release_id, fn changeset ->
          notes_changeset(changeset.data, params)
        end)
      )

    {:noreply, socket}
  end

  def handle_event("notes-submit", %{"notes" => %{"release_id" => release_id} = params}, socket) do
    release_id = String.to_integer(release_id)
    changeset = Map.fetch!(socket.assigns.notes_editing, release_id)
    changeset = notes_changeset(changeset.data, params)

    socket =
      if changeset.valid? do
        notes = Ecto.Changeset.get_field(changeset, :notes)
        release_id = Ecto.Changeset.get_field(changeset, :release_id)

        username = socket.assigns.username

        socket
        |> start_async({:notes_update, release_id}, fn ->
          Wantlists.update_wantlist(username, release_id, notes: notes)
        end)
        |> update(:notes_editing, &Map.put(&1, release_id, {:pending, notes}))
      else
        Logger.warning("Attempted to submit a notes form with errors: #{inspect(changeset)}",
          error: inspect(changeset.errors)
        )

        socket
      end

    {:noreply, socket}
  end

  def handle_event("refresh-wantlist", _params, socket) do
    username = socket.assigns.username

    case ObanDispatcher.dispatch_wantlist(username) do
      {:ok, _job} ->
        {:noreply,
         socket
         |> put_notification(NormalNotification.new(:info, "Needlist refresh started."))
         |> assign_last_wantlist_update()
         |> maybe_schedule_refresh_ready()}

      {:error, reason} ->
        Logger.error("Failed to dispatch wantlist refresh for #{username}: #{inspect(reason)}",
          error: inspect(reason),
          user: username
        )

        {:noreply, put_flash(socket, :error, "Failed to refresh needlist! Please try again later.")}
    end
  end

  def handle_event("notification", %{"value" => value}, socket) do
    socket =
      Toaster.put_flash(
        socket,
        String.to_existing_atom(value),
        "This is a test notification. It should be replaced by a real one."
      )

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

  def handle_async({:wantlist_update, release_id}, {:ok, {:ok, wantlist}}, socket) do
    socket =
      socket
      |> update(:current_page, &replace_page_entry(&1, wantlist))
      |> update(:pending_wantlist_updates, &Map.delete(&1, release_id))

    {:noreply, update(socket, :current_page, &replace_page_entry(&1, wantlist))}
  end

  def handle_async({:wantlist_update, release_id}, error_result, socket) do
    case error_result do
      {:ok, {:error, error}} ->
        Logger.warning("Failed to update release #{release_id} for #{socket.assigns.username}: #{inspect(error)}",
          error: inspect(error)
        )

      {:exit, reason} ->
        Logger.error("Release update failed with reason: #{inspect(reason)}", error: inspect(reason))
    end

    socket =
      socket
      |> put_flash(:error, "Failed to update rating")
      |> update(:pending_wantlist_updates, &Map.delete(&1, release_id))

    {:noreply, socket}
  end

  def handle_async({:notes_update, release_id}, {:ok, {:ok, wantlist}}, socket) do
    socket =
      socket
      |> update(:current_page, &replace_page_entry(&1, wantlist))
      |> update(:notes_editing, &Map.delete(&1, release_id))

    {:noreply, update(socket, :current_page, &replace_page_entry(&1, wantlist))}
  end

  def handle_async({:notes_update, release_id}, error_result, socket) do
    case error_result do
      {:ok, {:error, error}} ->
        Logger.warning("Failed to update release #{release_id} for #{socket.assigns.username}: #{inspect(error)}",
          error: inspect(error)
        )

      {:exit, reason} ->
        Logger.error("Release update failed with reason: #{inspect(reason)}", error: inspect(reason))
    end

    socket =
      socket
      |> put_flash(:error, "Failed to update notes")
      |> update(:notes_editing, &Map.delete(&1, release_id))

    {:noreply, socket}
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
  @spec load_page(Socket.t(), QueryOptions.options()) :: Socket.t()
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

  @spec fetch_page(String.t(), QueryOptions.options()) :: {:ok, paginated_wants()} | {:error, any()}
  defp fetch_page(username, needlist_options) do
    needlist = Wantlists.get_needlist_page(username, needlist_options)
    total = Wantlists.needlist_size(username)

    page = Keyword.get(needlist_options, :page, 1)
    per_page = Keyword.get(needlist_options, :per_page, 50)

    {:ok, Pagination.from_page(needlist, page, per_page, total)}
  end

  @spec replace_page_entry(current_page :: paginated_wants(), Wantlist.t()) :: paginated_wants()
  defp replace_page_entry(current_page, %Wantlist{release_id: release_id} = wantlist) do
    put_in(current_page, [Access.elem(1), Access.key(:items), Access.find(&(&1.release_id == release_id))], wantlist)
  end

  @spec notes_changeset(data :: map(), params :: map()) :: Ecto.Changeset.t()
  @spec notes_changeset(data :: map()) :: Ecto.Changeset.t()
  defp notes_changeset(data, params \\ %{}) do
    types = %{release_id: :integer, notes: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:release_id, :notes])
  end

  defp maybe_assign_timezone(socket) do
    maybe_tz =
      case get_connect_params(socket) do
        %{"time_zone" => time_zone} ->
          time_zone

        _ ->
          "UTC"
      end

    assign(socket, :time_zone, maybe_tz)
  end

  defp assign_last_wantlist_update(socket) do
    last_wantlist_update = Users.last_wantlist_update(socket.assigns.username, true)
    last_wantlist_update_attempt = Users.last_wantlist_update(socket.assigns.username, false)

    socket
    |> assign(:last_wantlist_update, last_wantlist_update)
    |> assign(:refresh_ready, wantlist_refresh_ready(last_wantlist_update_attempt, Timex.now()))
  end

  defp maybe_schedule_refresh_ready(socket) do
    refresh_ready = socket.assigns.refresh_ready

    if connected?(socket) and refresh_ready != nil do
      Process.send_after(
        self(),
        :refresh_ready,
        Timex.diff(refresh_ready, Timex.now(), :millisecond) + @refresh_ready_offset_ms
      )
    end

    socket
  end

  defp want_artists(assigns) do
    ~H"""
    <%= for artist <- @artists do %>
      <.want_artist artist={artist} />
      <%= if artist.join do %>
        {artist.join}
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
      {@year}
    <% end %>
    """
  end

  defp want_price(assigns) do
    ~H"""
    {@price}
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

  defp header_sorting(%{sort_order: sort_order} = assigns) do
    maybe_rotated =
      case sort_order do
        :asc -> nil
        :desc -> "rotate-180"
      end

    assigns = assign(assigns, :rotated, maybe_rotated)

    ~H"""
    <span class={"transition-all duration-300 #{@rotated}"}>
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
    </span>
    """
  end

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

  defp table_header(assigns) do
    assigns = assign_new(assigns, :column_key, fn -> nil end)

    phx_attrs =
      if assigns.column_key != nil do
        %{"phx-click": "sort-by", "phx-value-key": assigns.column_key}
      else
        %{}
      end

    assigns =
      assigns
      |> assign(:phx_attrs, phx_attrs)
      |> assign_new(:class, fn -> nil end)

    ~H"""
    <th scope="col" class={"px-6 py-3 #{@class}"} {@phx_attrs}>
      <span class={"inline-flex items-center font-medium #{@column_key != nil && "cursor-pointer text-blue-600 dark:text-blue-300 hover:underline"}"}>
        {@column_name}
        <%= if @state.sort_key == @column_key and @state.sort_order != nil do %>
          <.header_sorting sort_order={@state.sort_order} />
        <% end %>
      </span>
    </th>
    """
  end

  attr :datetime, DateTime, required: true
  attr :timezone, :string, default: "UTC"

  defp local_datetime(assigns) do
    ~H"""
    <span>
      {format_timestamp(@datetime, @timezone)}
    </span>
    """
  end

  attr :refresh_ready, :any, required: true
  attr :time_zone, :string, required: true

  defp refresh_wantlist(%{refresh_ready: nil} = assigns) do
    ~H"""
    <.button phx-click="refresh-wantlist" phx-disable-with="Refreshing...">
      Refresh needlist
    </.button>
    """
  end

  defp refresh_wantlist(%{refresh_ready: %DateTime{}} = assigns) do
    ~H"""
    <.button phx-click="refresh-wantlist" disabled>
      Refresh ready at {format_timestamp(@refresh_ready, @time_zone)}
    </.button>
    """
  end

  @spec format_timestamp(DateTime.t(), String.t()) :: String.t()
  defp format_timestamp(datetime, timezone) do
    datetime
    |> DateTime.shift_zone!(timezone)
    |> Timex.format!(@datetime_format)
  end

  @spec wantlist_refresh_ready(last_update :: DateTime.t() | nil, current_time :: DateTime.t()) :: DateTime.t() | nil
  defp wantlist_refresh_ready(nil, _current_time), do: nil

  defp wantlist_refresh_ready(last_update, current_time) do
    next_update = Timex.add(last_update, @update_interval)

    if Timex.compare(current_time, next_update) < 0 do
      next_update
    else
      nil
    end
  end
end

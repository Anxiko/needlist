defmodule NeedlistWeb.NeedlistLive do
  alias Needlist.Discogs.Pagination.PageInfo
  alias Needlist.Repo.Pagination
  alias Needlist.Repo.Wantlist
  alias Needlist.Types.QueryOptions
  alias Needlist.Types.QueryOptions.SortKey
  alias Needlist.Types.QueryOptions.SortOrder
  alias Needlist.Wantlists
  alias NeedlistWeb.NeedlistLive.State
  alias Nullables.Fallible
  alias Phoenix.LiveView.Socket

  use NeedlistWeb, :live_view

  import NeedlistWeb.Navigation.Components, only: [pagination: 1]

  require Logger

  @initial_sorting_order :asc

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

  def handle_event("edit-note", %{"release-id" => release_id, "notes" => notes}, socket) do
    release_id = String.to_integer(release_id)
    changeset = notes_changeset(%{release_id: release_id, note: notes})

    socket =
      update(socket, :notes_editing, &Map.put(&1, release_id, changeset))

    {:noreply, socket}
  end

  def handle_event("cancel-note", %{"release-id" => release_id}, socket) do
    release_id = String.to_integer(release_id)

    socket = update(socket, :notes_editing, &MapSet.delete(&1, release_id))

    {:noreply, socket}
  end

  def handle_event("save-note", %{"release-id" => release_id}, socket) do
    release_id = String.to_integer(release_id)

    socket = update(socket, :notes_editing, &MapSet.delete(&1, release_id))

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

    socket =
      update(socket, :notes_editing, fn mapped_changesets ->
        changeset = Map.fetch!(mapped_changesets, release_id)

        case notes_changeset(changeset.data, params) do
          %Ecto.Changeset{valid?: true} = changeset ->
            notes = Ecto.Changeset.get_field(changeset, :notes)
            release_id = Ecto.Changeset.get_field(changeset, :release_id)

            socket
            |> update(
              :current_page,
              &update_page_entry(&1, release_id, fn wantlist -> %{wantlist | notes: notes} end)
            )
            |> update(:notes_editing, &Map.delete(&1, release_id))

          changeset ->
            Logger.warning("Attempted to submit a notes form with errors: #{inspect(changeset)}",
              error: inspect(changeset.errors)
            )

            socket
        end
      end)

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

  def handle_async({:wantlist_update, release_id}, result, socket) do
    socket =
      case result do
        {:ok, {:ok, wantlist}} ->
          update(socket, :current_page, &replace_page_entry(&1, wantlist))

        {:ok, {:error, error}} ->
          Logger.warning("Failed to update release #{release_id} for #{socket.assigns.username}: #{inspect(error)}",
            error: inspect(error)
          )

        {:exit, reason} ->
          Logger.error("Release update failed with reason: #{inspect(reason)}", error: inspect(reason))
      end
      |> update(:pending_wantlist_updates, &Map.delete(&1, release_id))

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

  @spec update_page_entry(current_page :: paginated_wants(), release_id :: integer(), (Wantlist.t() -> Wantlist.t())) ::
          paginated_wants()
  defp update_page_entry(current_page, release_id, updater) do
    update_in(current_page, [Access.elem(1), Access.key(:items), Access.find(&(&1.release_id == release_id))], updater)
  end

  @spec notes_changeset(data :: map(), params :: map()) :: Ecto.Changeset.t()
  @spec notes_changeset(data :: map()) :: Ecto.Changeset.t()
  defp notes_changeset(data, params \\ %{}) do
    types = %{release_id: :integer, notes: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:release_id, :notes])
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
end

defmodule NeedlistWeb.Components.Notifications.Normal do
  @moduledoc """
  Flashy notifications meant for regular use, to replace LiveView's flash notifications.
  """

  use NeedlistWeb, :html

  use Flashy.Normal, types: [:info, :success, :warning, :danger]

  attr :key, :string, required: true
  attr :notification, Flashy.Normal, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Normal.render key={@key} notification={@notification}>
      <div
        class="relative overflow-hidden flex items-center w-full max-w-xs p-4 text-gray-500 rounded-lg shadow-sm dark:text-gray-400 bg-gray-300 dark:bg-gray-700"
        role="alert"
      >
        <.notification_icon type={@notification.type} />

        <div class="ms-3 text-sm font-normal">{@notification.message}</div>

        <button
          type="button"
          class="ms-auto -mx-1.5 -my-1.5 bg-white text-gray-400 hover:text-gray-900 rounded-lg focus:ring-2 focus:ring-gray-300 p-1.5 hover:bg-gray-100 inline-flex items-center justify-center h-8 w-8 dark:text-gray-500 dark:hover:text-white dark:bg-gray-800 dark:hover:bg-gray-700"
          data-dismiss-target="#toast-default"
          aria-label="Close"
          phx-click={JS.exec("data-hide", to: "#" <> @key)}
        >
          <span class="sr-only">Close</span>
          <svg class="w-3 h-3" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 14">
            <path
              stroke="currentColor"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"
            />
          </svg>
        </button>

        <.progress_bar :if={@notification.options.dismissible?} id={"#{@key}-progress"} />
      </div>
    </Flashy.Normal.render>
    """
  end

  attr :id, :string, required: true

  defp progress_bar(assigns) do
    ~H"""
    <div id={@id} class="absolute bottom-0 left-0 h-1 bg-black/10 dark:bg-white/10" style="width: 0%" />
    """
  end

  attr :type, :atom, required: true

  defp notification_icon(assigns) do
    {heroicon, icon_color, bg_color} =
      case assigns.type do
        :success -> {"hero-check", "text-green-500", "bg-green-100"}
        :info -> {"hero-information-circle-solid", "text-blue-500", "bg-blue-100"}
        :warning -> {"hero-exclamation-circle-solid", "text-amber-500", "bg-amber-100"}
        :danger -> {"hero-x-circle-solid", "text-red-500", "bg-red-100"}
      end

    assigns = assign(assigns, heroicon: heroicon, icon_color: icon_color, bg_color: bg_color)

    ~H"""
    <div class={["inline-flex items-center justify-center shrink-0 w-8 h-8 rounded-lg", @icon_color, @bg_color]}>
      <.icon name={@heroicon} />
      <span class="sr-only">Icon for {@type} notification</span>
    </div>
    """
  end
end

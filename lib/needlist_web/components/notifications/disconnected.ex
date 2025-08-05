defmodule NeedlistWeb.Components.Notifications.Disconnected do
  @moduledoc false

  use NeedlistWeb, :html

  use Flashy.Disconnected

  attr :key, :string, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Disconnected.render key={@key}>
      <div
        id="toast-simple"
        class="flex items-center w-full max-w-xs p-4 space-x-4 rtl:space-x-reverse text-gray-500 bg-white divide-x rtl:divide-x-reverse divide-gray-200 rounded-lg shadow-sm dark:text-gray-400 dark:divide-gray-700 dark:bg-gray-800"
        role="alert"
      >
        <div class="ps-4 text-sm font-normal">Attempting to reconnect.</div>
      </div>
    </Flashy.Disconnected.render>
    """
  end
end

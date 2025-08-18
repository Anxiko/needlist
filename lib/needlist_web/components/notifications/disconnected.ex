defmodule NeedlistWeb.Components.Notifications.Disconnected do
  @moduledoc false

  use NeedlistWeb, :html

  use Flashy.Disconnected

  attr :key, :string, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Disconnected.render key={@key}>
      <div
        class="flex items-center gap-1 w-full max-w-xs p-4 text-gray-500 rounded-lg shadow-sm dark:text-gray-400 bg-gray-300 dark:bg-gray-700"
        role="alert"
      >
        <.icon name="hero-arrow-path" class="animate-spin" />
        <div class="text-sm font-normal">Attempting to reconnect...</div>
      </div>
    </Flashy.Disconnected.render>
    """
  end
end

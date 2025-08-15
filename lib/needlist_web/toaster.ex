defmodule NeedlistWeb.Toaster do
  @moduledoc """
  Module to push toast notifications, intended as a drop in replacement for LiveView's own `put_flash/3`, but using Flashy.
  """

  alias NeedlistWeb.Components.Notifications.Normal, as: NormalNotification

  @type flash_type :: NormalNotification.notification_type() | :error

  @spec put_flash(socket_or_conn :: Phoenix.Socket.t() | Plug.Conn.t(), type :: atom(), message :: String.t()) ::
          Phoenix.Socket.t() | Plug.Conn.t()
  def put_flash(socket_or_conn, type, message) do
    Flashy.put_notification(socket_or_conn, NormalNotification.new(flash_type(type), message))
  end

  @spec flash_type(flash_type()) :: NormalNotification.type()
  defp flash_type(:error), do: :danger
  defp flash_type(valid) when valid in [:success, :info, :warning, :danger], do: valid
end

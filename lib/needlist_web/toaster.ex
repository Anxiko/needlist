defmodule NeedlistWeb.Toaster do
  @moduledoc """
  Module to push toast notifications, intended as a drop in replacement for LiveView's own `put_flash/3`, but using Flashy.
  """

  alias NeedlistWeb.Components.Notifications.Normal, as: NormalNotification

  @type flash_type :: NormalNotification.notification_type() | :error

  @spec put_flash(socket_or_conn :: Phoenix.LiveView.Socket.t() | Plug.Conn.t(), type :: atom(), message :: String.t()) ::
          Phoenix.LiveView.Socket.t() | Plug.Conn.t()
  def put_flash(socket_or_conn, type, message) do
    Flashy.put_notification(socket_or_conn, NormalNotification.new(flash_type(type), message))
  end

  @spec get_flash(flash_assigns :: map(), type :: flash_type()) :: [String.t()]
  def get_flash(flash_assigns, type) do
    flash_assigns
    |> Map.values()
    |> Enum.filter(fn
      %Flashy.Normal{type: ^type} -> true
      _ -> false
    end)
    |> Enum.map(fn %Flashy.Normal{message: message} -> message end)
  end

  @spec flash_type(flash_type()) :: NormalNotification.type()
  defp flash_type(:error), do: :danger
  defp flash_type(valid) when valid in [:success, :info, :warning, :danger], do: valid
end

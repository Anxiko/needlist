defmodule NeedlistWeb.Asserters do
  @moduledoc """
  Helper functions for test assertions.
  """

  @spec contains_flash_message?(
          flash_assigns_or_conn :: Plug.Conn.t() | map(),
          type :: atom(),
          message :: String.t() | Regex.t()
        ) :: boolean()
  def contains_flash_message?(%Plug.Conn{} = conn, type, message) do
    contains_flash_message?(conn.assigns.flash, type, message)
  end

  def contains_flash_message?(flash_assigns, type, message) when is_non_struct_map(flash_assigns) do
    flash_assigns
    |> NeedlistWeb.Toaster.get_flash(type)
    |> Enum.any?(&(&1 =~ message))
  end
end

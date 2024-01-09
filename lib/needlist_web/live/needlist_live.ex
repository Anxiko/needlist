defmodule NeedlistWeb.NeedlistLive do
  use NeedlistWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :list, [1, 2, 3])}
  end
end

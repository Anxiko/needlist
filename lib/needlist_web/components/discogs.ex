defmodule NeedlistWeb.Components.Discogs do
  @moduledoc """
  HTML components for Discogs
  """

  use NeedlistWeb, :html

  def want(assigns) do
    ~H"""
    <div>
      <%=@item.title %> - <%= @item.title %>
    </div>
    """
  end
end

defmodule NeedlistWeb.Components.Discogs do
  use NeedlistWeb, :html

  def want(assigns) do
    ~H"""
    <div>
      <%=@item.title %> - <%= @item.title %>
    </div>
    """
  end
end

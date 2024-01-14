defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

  import Needlist.Discogs.Guards, only: [is_pos_integer: 1]

  alias Needlist.Discogs.Model.Want
  alias Needlist.Discogs.Pagination.Page

  @spec base_api_url() :: String.t()
  def base_api_url(), do: "https://api.discogs.com"

  @spec get_user_needlist(String.t()) :: {:ok, Page.t(Want.t())} | :error
  @spec get_user_needlist(String.t(), pos_integer()) :: {:ok, Page.t(Want.t())} | :error
  def get_user_needlist(user, page \\ 1) when is_pos_integer(page) do
    user = URI.encode(user)

    base_api_url()
    |> Kernel.<>("/users/#{user}/wants")
    |> then(&Req.new(url: &1, method: :get, params: [page: page]))
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Page.parse_page(body, "wants", &Want.parse/1)

      _ ->
        :error
    end
  end
end

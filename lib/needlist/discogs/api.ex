defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

  import Needlist.Guards, only: [is_pos_integer: 1]

  alias Needlist.Discogs.Model.Want
  alias Needlist.Discogs.Pagination.Page

  @spec base_api_url() :: String.t()
  def base_api_url(), do: "https://api.discogs.com"

  @type sort_key() :: :label | :artist | :title | :catno | :format | :rating | :added | :year
  @type sort_order() :: :asc | :desc

  @type needlist_option() :: [page: pos_integer(), sort_key: sort_key(), sort_order: sort_order()]

  @spec get_user_needlist(String.t()) :: {:ok, Page.t(Want.t())} | :error
  @spec get_user_needlist(String.t(), needlist_option()) :: {:ok, Page.t(Want.t())} | :error
  def get_user_needlist(user, opts \\ []) do
    page = extract_page!(opts)
    user = URI.encode(user)

    params =
      [page: page]
      |> add_sorting(opts)

    base_api_url()
    |> Kernel.<>("/users/#{user}/wants")
    |> then(&Req.new(url: &1, method: :get, params: params))
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Page.parse_page(body, "wants", &Want.parse/1)

      _ ->
        :error
    end
  end

  defp extract_page!(opts) do
    opts
    |> Keyword.fetch(:page)
    |> case do
      {:ok, page} when is_pos_integer(page) -> page
      :error -> 1
    end
  end

  defp add_sorting(params, opts) do
    opts =
      opts
      |> Keyword.take([:sort_key, :sort_value])
      |> Keyword.new(fn {k, v} -> {k, Atom.to_string(v)} end)

    Keyword.merge(params, opts)
  end
end

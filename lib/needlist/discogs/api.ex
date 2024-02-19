defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

  import Needlist.Guards, only: [is_pos_integer: 1]

  alias Needlist.Discogs.Api.Types.SortOrder
  alias Needlist.Discogs.Api.Types.SortKey
  alias Needlist.Discogs.Model.Want
  alias Needlist.Discogs.Pagination

  @spec base_api_url() :: String.t()
  def base_api_url(), do: "https://api.discogs.com"

  @type sort_key() :: SortKey.t()
  @type sort_order() :: SortOrder.t()

  @type needlist_options() :: [
          page: pos_integer(),
          per_page: pos_integer(),
          sort: sort_key(),
          sort_order: sort_order()
        ]

  @spec get_user_needlist(String.t()) :: {:ok, Pagination.t(Want.t())} | :error
  @spec get_user_needlist(String.t(), needlist_options()) :: {:ok, Pagination.t(Want.t())} | :error
  def get_user_needlist(user, opts \\ []) do
    page = extract_page!(opts)
    user = URI.encode(user)

    IO.inspect(opts, label: "Opts")

    params =
      [page: page]
      |> Keyword.merge(opts_to_params(opts))
      |> IO.inspect(label: "Opts to params")

    base_api_url()
    |> Kernel.<>("/users/#{user}/wants")
    |> then(&Req.new(url: &1, method: :get, params: params))
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Pagination.parse_page(body, "wants", &Want.parse/1)

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

  @spec opts_to_params(needlist_options()) :: Keyword.t()
  defp opts_to_params(opts) do
    [:sort, :sort_value]
    |> Enum.reduce(opts, fn key, opts -> Keyword.replace_lazy(opts, key, &Atom.to_string/1) end)
  end
end

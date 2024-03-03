defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

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
    user = URI.encode(user)

    params = opts_to_params(opts)

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

  @spec opts_to_params(needlist_options()) :: Keyword.t()
  defp opts_to_params(opts) do
    opts
    |> Keyword.filter(fn {_k, v} -> v != nil end)
    |> Keyword.new(fn {k, v} -> {k, atom_to_string(v)} end)
  end

  defp atom_to_string(v) when is_atom(v), do: Atom.to_string(v)
  defp atom_to_string(v), do: v
end

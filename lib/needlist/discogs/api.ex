defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

  alias Nullables.Fallible
  alias Nullables.Result
  alias Needlist.Discogs.Api.Types.SortOrder
  alias Needlist.Discogs.Api.Types.SortKey
  alias Needlist.Discogs.Model.Want
  alias Needlist.Discogs.Pagination
  alias Needlist.Repo.Pagination, as: RepoPagination
  alias Needlist.Repo.Want, as: RepoWant

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

  @spec get_user_needlist_raw(String.t(), needlist_options()) :: {:ok, map()} | :error
  defp get_user_needlist_raw(user, opts) do
    user = URI.encode(user)

    params = opts_to_params(opts)

    base_api_url()
    |> Kernel.<>("/users/#{user}/wants")
    |> then(&Req.new(url: &1, method: :get, params: params))
    |> Req.request()
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      _ ->
        :error
    end
  end

  @spec get_user_needlist(String.t()) :: {:ok, Pagination.t(Want.t())} | :error
  @spec get_user_needlist(String.t(), needlist_options()) :: {:ok, Pagination.t(Want.t())} | :error
  def get_user_needlist(user, opts \\ []) do
    user
    |> get_user_needlist_raw(opts)
    |> Fallible.map(fn body -> Pagination.parse_page(body, "wants", &Want.parse/1) end)
  end

  @spec get_user_needlist_repo(String.t(), needlist_options()) ::
          Result.result(RepoPagination.t(Want.t()), Ecto.Changeset.t(RepoPagination.t(Want.t())))
  @spec get_user_needlist_repo(String.t()) ::
          Result.result(RepoPagination.t(Want.t()), Ecto.Changeset.t(RepoPagination.t(Want.t())))
  def get_user_needlist_repo(user, opts \\ []) do
    user
    |> IO.inspect(label: "User")
    |> get_user_needlist_raw(opts)
    |> IO.inspect(label: "Raw result")
    |> Nullables.fallible_to_result(:request)
    |> Result.flat_map(&RepoPagination.parse(&1, :wants, RepoWant))
    |> IO.inspect(label: "get_user_needlist_repo")
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

defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

  alias Needlist.Discogs.Oauth
  alias Nullables.Result
  alias Needlist.Discogs.Api.Types.Identity
  alias Needlist.Discogs.Api.Types.SortOrder
  alias Needlist.Discogs.Api.Types.SortKey
  alias Needlist.Repo.Pagination, as: RepoPagination
  alias Needlist.Repo.Want
  alias Needlist.Repo.User

  @base_api_url :needlist |> Application.compile_env!(Needlist.Discogs) |> Keyword.fetch!(:base_api_url)

  @type sort_key() :: SortKey.t()
  @type sort_order() :: SortOrder.t()

  @type needlist_options() :: [
          page: pos_integer(),
          per_page: pos_integer(),
          sort: sort_key(),
          sort_order: sort_order()
        ]

  @spec get_user_needlist_repo(String.t(), needlist_options()) ::
          Result.result(RepoPagination.t(Want.t()), Ecto.Changeset.t(RepoPagination.t(Want.t())))
  @spec get_user_needlist_repo(String.t()) ::
          Result.result(RepoPagination.t(Want.t()), Ecto.Changeset.t(RepoPagination.t(Want.t())))
  def get_user_needlist_repo(user, opts \\ []) do
    user
    |> get_user_needlist_raw(opts)
    |> Nullables.fallible_to_result(:request)
    |> Result.flat_map(&RepoPagination.parse(&1, :wants, Want))
  end

  @spec get_user(String.t()) :: Result.result(User.t(), any())
  def get_user(username) do
    username = URI.encode(username)

    base_api_url()
    |> Kernel.<>("/users/#{username}")
    |> then(&Req.new(url: &1, method: :get))
    |> Req.request()
    |> Result.flat_map(&body_from_ok/1)
    |> Result.flat_map(&User.cast/1)
  end

  @spec identity(access_token_pair :: Oauth.token_pair()) :: Result.result(Identity.t())
  def identity(access_token_pair) do
    credentials = Oauth.oauther_credentials(access_token_pair)

    base_api_url()
    |> Kernel.<>("/oauth/identity")
    |> then(&Req.new(url: &1, method: :get))
    |> Oauth.authenticate_request(credentials)
    |> Req.request()
    |> Result.flat_map(&body_from_ok/1)
    |> Result.flat_map(&Identity.cast/1)
  end

  @spec base_api_url() :: String.t()
  defp base_api_url(), do: @base_api_url

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

  @spec opts_to_params(needlist_options()) :: Keyword.t()
  defp opts_to_params(opts) do
    opts
    |> Keyword.filter(fn {_k, v} -> v != nil end)
    |> Keyword.new(fn {k, v} -> {k, atom_to_string(v)} end)
  end

  defp atom_to_string(v) when is_atom(v), do: Atom.to_string(v)
  defp atom_to_string(v), do: v

  defp body_from_ok(response, expected_status \\ 200)
  defp body_from_ok(%Req.Response{status: status, body: body}, status), do: {:ok, body}

  defp body_from_ok(%Req.Response{status: actual}, expected) do
    {:error, "Expected status #{expected}, got #{actual}"}
  end
end

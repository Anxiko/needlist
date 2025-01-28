defmodule Needlist.Discogs.Api do
  @moduledoc """
  Discogs API client
  """

  import Nullables.Result, only: [tag_error: 2]

  alias Needlist.Discogs.Oauth
  alias Needlist.Types.QueryOptions
  alias Needlist.Discogs.Api.Types.Identity
  alias Needlist.Repo.Pagination, as: RepoPagination
  alias Needlist.Repo.Want
  alias Needlist.Repo.User
  alias Needlist.Users
  alias Nullables.Result

  @base_api_url :needlist |> Application.compile_env!(Needlist.Discogs) |> Keyword.fetch!(:base_api_url)

  @spec get_user_needlist(username :: String.t(), options :: QueryOptions.options()) ::
          Result.result(RepoPagination.t(Want.t()), Ecto.Changeset.t(RepoPagination.t(Want.t())))
  @spec get_user_needlist(username :: String.t()) ::
          Result.result(RepoPagination.t(Want.t()), Ecto.Changeset.t(RepoPagination.t(Want.t())))
  def get_user_needlist(username, opts \\ []) do
    [
      base_url: base_api_url(),
      url: "/users/#{URI.encode(username)}/wants",
      params: opts_to_params(opts),
      method: :get
    ]
    |> Req.new()
    |> maybe_authenticate_request_with_user(username)
    |> Req.request()
    |> Result.flat_map(&body_from_ok/1)
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

  @spec opts_to_params(QueryOptions.options()) :: Keyword.t()
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

  # TODO: verify that the tokens are not expired
  @spec fetch_user_tokens(username :: String.t()) :: Result.result(Oauth.token_pair())
  defp fetch_user_tokens(username) do
    with {:ok, %User{oauth: oauth}} <- Users.get_by_username(username) |> tag_error(:user),
         {:ok, oauth} <- Nullables.nullable_to_result(oauth, :token) do
      {:ok, User.Oauth.token_pair(oauth)}
    else
      error -> Nullables.normalize(error)
    end
  end

  @spec maybe_authenticate_request_with_user(request :: Req.Request.t(), username :: String.t()) :: Req.Request.t()
  defp maybe_authenticate_request_with_user(request, username) do
    case fetch_user_tokens(username) do
      {:ok, token_pair} ->
        credentials = Oauth.oauther_credentials(token_pair)
        Oauth.authenticate_request(request, credentials)

      _ ->
        request
    end
  end
end

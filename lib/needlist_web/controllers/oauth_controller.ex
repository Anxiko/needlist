defmodule NeedlistWeb.OauthController do
  use NeedlistWeb, :controller

  import Nullables.Result, only: [tag_error: 2]

  require Logger
  alias Needlist.Users
  alias Needlist.Discogs.Api
  alias Needlist.Discogs.Api.Types.Identity
  alias Needlist.Discogs.Oauth

  @cache Application.compile_env!(:needlist, :cache_key)

  @spec request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def request(conn, _params) do
    oauth_callback = callback_url()

    with {:ok, request_token_pair} <- Oauth.generate_oauth_request_tokens(oauth_callback) |> tag_error(:request),
         {:ok, _} <- save_token_pair(request_token_pair) |> tag_error(:cache_request) do
      verify_url = Oauth.verify_url(request_token_pair)
      redirect(conn, external: verify_url)
    else
      error ->
        Logger.warning("Error on OAuth request token creation and redirect: #{error}")

        conn
        |> put_status(500)
        |> text("An error occurred during the login and redirect process. You may refresh this page to try again.")
    end
  end

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def callback(conn, %{"oauth_token" => oauth_token, "oauth_verifier" => oauth_verifier}) do
    with {:ok, request_token_pair} <- retrieve_token_pair(oauth_token) |> tag_error(:cache),
         {:ok, access_token_pair} <-
           Oauth.generate_oauth_access_tokens(request_token_pair, oauth_verifier) |> tag_error(:access),
         {:ok, %Identity{id: id, username: username}} <-
           Api.identity(access_token_pair) |> tag_error(:identity),
         {:ok, _} <- Users.upsert_user_with_oauth_tokens(id, username, access_token_pair) do
      conn
      |> put_status(200)
      |> text("You are now logged in as #{username}")
    else
      error ->
        Logger.warning("Failed to process OAuth callback: #{inspect(error)}", error: error)

        conn
        |> put_status(500)
        |> text("An error occurred during the final authorization step.")
    end
  end

  defp callback_url do
    url(~p"/oauth/callback")
  end

  defp save_token_pair({request_token, request_token_secret}) do
    Cachex.put(@cache, request_token, request_token_secret)
  end

  defp retrieve_token_pair(request_token) do
    case Cachex.get(@cache, request_token) do
      {:ok, nil} ->
        {:error, :not_found}

      {:ok, request_token_secret} when is_binary(request_token_secret) ->
        {:ok, {request_token, request_token_secret}}
    end
  end
end

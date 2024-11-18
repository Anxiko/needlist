defmodule NeedlistWeb.OauthController do
  use NeedlistWeb, :controller

  import Nullables.Result, only: [tag_error: 2]

  require Logger
  alias Needlist.Discogs.Oauth

  @cache Application.compile_env!(:needlist, :cache_key)

  @spec request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def request(conn, _params) do
    with {:ok, request_token_pair} = Oauth.generate_oauth_request_tokens() |> tag_error(:request),
         {:ok, _} <- save_token_pair(request_token_pair) |> tag_error(:cache_request),
         verify_url = Oauth.verify_url(request_token_pair) do
      redirect(conn, external: verify_url)
    else
      error ->
        Logger.warning("Error on OAuth request token creation and redirect: #{error}")

        conn
        |> put_status(500)
        |> text("An error occurred during the login and redirect process. You may refresh this page to try again.")
    end
  end

  defp save_token_pair({token, token_secret}) do
    Cachex.put(@cache, token, token_secret)
  end
end

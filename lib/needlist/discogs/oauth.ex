defmodule Needlist.Discogs.Oauth do
  @moduledoc """
  Handle OAuth authentication for Discogs, generate OAuth tokens for authenticated user requests
  """

  @type token_pair() :: {String.t(), String.t()}

  @base_api_url :needlist |> Application.compile_env!(Needlist.Discogs) |> Keyword.fetch!(:base_api_url)
  @base_web_url :needlist |> Application.compile_env!(Needlist.Discogs) |> Keyword.fetch!(:base_web_url)

  @spec generate_oauth_request_tokens() :: Nullables.Result.result(token_pair())
  def generate_oauth_request_tokens do
    request_token_url = @base_api_url <> "/oauth/request_token"

    :post
    |> authenticated_request(request_token_url, nil)
    |> Req.request()
    |> Nullables.Result.flat_map(&extract_tokens_from_response/1)
  end

  @spec generate_oauth_access_tokens(token_pair(), String.t()) :: Nullables.Result.result(token_pair())
  def generate_oauth_access_tokens(request_tokens, verifier) do
    access_token_url = @base_api_url <> "/oauth/access_token"

    :post
    |> authenticated_request(access_token_url, request_tokens, [{"oauth_verifier", verifier}])
    |> Req.request()
    |> Nullables.Result.flat_map(&extract_tokens_from_response/1)
  end

  @spec verify_url(request_tokens :: token_pair()) :: String.t()
  def verify_url({request_token, _request_token_secret}) do
    query = URI.encode_query(oauth_token: request_token)

    (@base_web_url <> "/oauth/authorize")
    |> URI.parse()
    |> URI.append_query(query)
    |> URI.to_string()
  end

  @spec authenticated_request(
          method :: atom(),
          url :: String.t(),
          token_pair :: token_pair() | nil,
          query_args :: [{String.t(), String.t()}]
        ) :: Req.Request.t()
  @spec authenticated_request(
          method :: atom(),
          url :: String.t(),
          token_pair :: token_pair() | nil
        ) :: Req.Request.t()
  defp authenticated_request(method, url, token_pair, query_args \\ []) do
    credentials = oauther_credentials(token_pair)
    params = OAuther.sign(Atom.to_string(method), url, query_args, credentials)
    {header, query_args} = OAuther.header(params)

    Req.new(method: method, url: url, headers: [header], params: query_args)
  end

  @spec extract_tokens_from_response(response :: Req.Response.t()) :: Nullables.Result.result(token_pair())
  defp extract_tokens_from_response(response) do
    with {_, %Req.Response{status: 200, body: body}} when is_binary(body) <- {:request, response},
         {_, %{"oauth_token" => oauth_token, "oauth_token_secret" => oauth_token_secret}} <-
           {:response, URI.decode_query(body)} do
      {:ok, {oauth_token, oauth_token_secret}}
    else
      {step, {:error, details}} -> {:error, {step, details}}
      {step, _} -> {:error, step}
    end
  end

  @spec oauther_credentials(token_pair() | nil) :: OAuther.Credentials.t()
  defp oauther_credentials(tokens) do
    Application.fetch_env!(:needlist, Needlist.Discogs.Oauth)
    |> Keyword.take([:consumer_key, :consumer_secret])
    |> Keyword.put(:method, :plaintext)
    |> add_token_pair(tokens)
    |> OAuther.credentials()
  end

  @spec add_token_pair(keyword(), token_pair() | nil) :: keyword()
  defp add_token_pair(args, nil), do: args

  defp add_token_pair(args, {token, token_secret}) do
    Keyword.merge(args, token: token, token_secret: token_secret)
  end
end

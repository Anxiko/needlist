defmodule Needlist.Discogs.Oauth do
  @moduledoc """
  Handle OAuth authentication for Discogs, generate OAuth tokens for authenticated user requests
  """

  @type token_pair() :: {String.t(), String.t()}

  @base_api_url :needlist |> Application.compile_env!(Needlist.Discogs) |> Keyword.fetch!(:base_api_url)
  @base_web_url :needlist |> Application.compile_env!(Needlist.Discogs) |> Keyword.fetch!(:base_web_url)

  @spec generate_oauth_request_tokens(callback_url :: String.t() | nil) :: Nullables.Result.result(token_pair())
  @spec generate_oauth_request_tokens() :: Nullables.Result.result(token_pair())
  def generate_oauth_request_tokens(callback_url \\ nil) do
    request_token_url = @base_api_url <> "/oauth/request_token"

    opts =
      if callback_url != nil do
        [oauth_callback: callback_url]
      else
        []
      end

    :post
    |> authenticated_request(request_token_url, opts)
    |> Req.request()
    |> Nullables.Result.flat_map(&extract_tokens_from_response/1)
  end

  @spec generate_oauth_access_tokens(token_pair(), String.t()) :: Nullables.Result.result(token_pair())
  def generate_oauth_access_tokens(request_tokens, verifier) do
    access_token_url = @base_api_url <> "/oauth/access_token"

    :post
    |> authenticated_request(access_token_url, token_pair: request_tokens, oauth_verifier: verifier)
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

  @spec oauther_credentials(token_pair() | nil) :: OAuther.Credentials.t()
  def oauther_credentials(tokens) do
    Application.fetch_env!(:needlist, __MODULE__)
    |> Keyword.take([:consumer_key, :consumer_secret])
    |> Keyword.put(:method, :plaintext)
    |> add_token_pair(tokens)
    |> OAuther.credentials()
  end

  @spec authenticate_request(Req.Request.t(), OAuther.Credentials.t(), keyword()) :: Req.Request.t()
  @spec authenticate_request(Req.Request.t(), OAuther.Credentials.t()) :: Req.Request.t()
  def authenticate_request(
        %Req.Request{method: method, url: url, options: %{} = options} = request,
        credentials,
        extra_oauth_params \\ []
      ) do
    extra_oauth_params =
      extra_oauth_params
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)

    if non_oauth_extra_option = Enum.find(extra_oauth_params, fn {k, _v} -> not String.starts_with?(k, "oauth_") end) do
      raise ArgumentError,
        message: "Only OAuth options may be provided as extra options, found: #{non_oauth_extra_option}"
    end

    extra_query_params = (Map.get(options, :params) || %{}) |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    all_params = OAuther.sign(Atom.to_string(method), url, extra_query_params ++ extra_oauth_params, credentials)

    {{"Authorization", oauth_header}, _non_oauth_params} = OAuther.header(all_params)

    Req.Request.put_header(request, "Authorization", oauth_header)
  end

  @spec authenticated_request(
          method :: atom(),
          url :: String.t(),
          opts :: keyword()
        ) :: Req.Request.t()
  defp authenticated_request(method, url, opts) do
    {token_pair, opts} = Keyword.pop(opts, :token_pair)
    opts = Enum.map(opts, fn {k, v} -> {to_string(k), v} end)

    credentials = oauther_credentials(token_pair)
    params = OAuther.sign(Atom.to_string(method), url, opts, credentials)
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

  @spec add_token_pair(keyword(), token_pair() | nil) :: keyword()
  defp add_token_pair(args, nil), do: args

  defp add_token_pair(args, {token, token_secret}) do
    Keyword.merge(args, token: token, token_secret: token_secret)
  end
end

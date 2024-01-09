defmodule Needlist.Discogs.Api do
  import Needlist.Discogs.Guards, only: [is_pos_integer: 1]

  @spec base_api_url() :: String.t()
  def base_api_url(), do: "https://api.discogs.com"

  def get_user_needlist(user, page \\ 1) when is_pos_integer(page) do
    user = URI.encode(user)

    base_api_url()
    |> Kernel.<>("/users/#{user}/wants")
    |> then(&Req.new(url: &1, method: :get, params: [page: page]))
  end
end

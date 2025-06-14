defmodule NeedlistWeb.ApiAuth do
  import Plug.Conn

  @salt Application.compile_env!(:needlist, __MODULE__)[:salt]
  @key_id Application.compile_env!(:needlist, __MODULE__)[:key_id]

  @spec verify_api_conn(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def verify_api_conn(conn, _opts) do
    with ["Bearer " <> api_token] <- get_req_header(conn, "authorization"),
         {:ok, key_id} <- verify_api_token(api_token) do
      assign(conn, :api_key_id, key_id)
    else
      _ -> conn |> send_resp(401, "Unauthorized") |> halt()
    end
  end

  @spec verify_api_token(String.t()) :: {:ok, any()} | {:error, any()}
  defp verify_api_token(api_token) do
    with {:ok, key_id} when key_id == @key_id <- Phoenix.Token.verify(NeedlistWeb.Endpoint, @salt, api_token) do
      {:ok, key_id}
    else
      {:error, _} = error -> error
      {:ok, _unknown_key} -> {:error, :unknown_key}
    end
  end

  @spec generate_api_token() :: String.t()
  def generate_api_token do
    Phoenix.Token.sign(NeedlistWeb.Endpoint, @salt, @key_id)
  end
end

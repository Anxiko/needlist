defmodule Needlist.Python do
  @moduledoc """
  Interop with Python scripts
  """

  alias Nullables.Result
  @python_path [:code.priv_dir(:needlist), "python"] |> Path.join()
  @python_binary [@python_path, "venv/bin/python"] |> Path.join()

  @spec scrape_listings(integer()) :: Result.result(String.t())
  def scrape_listings(release_id) do
    case :python.start(python_path: String.to_charlist(@python_path), python: String.to_charlist(@python_binary)) do
      {:ok, pid} ->
        do_scrape_listings(pid, release_id)

      _ ->
        {:error, :python_process}
    end
  end

  @spec do_scrape_listings(pid(), integer()) :: Result.result(String.t())
  defp do_scrape_listings(pid, release_id) do
    pid
    |> :python.call(:discogs_scrapper, :scrape_listings, [release_id])
    |> case do
      {status_code, nil} -> {:error, {:status_code, status_code}}
      {_, response} -> {:ok, to_string(response)}
    end
  rescue
    e in ErlangError ->
      :python.stop(pid)
      {:error, {:python_call, e}}
  end
end
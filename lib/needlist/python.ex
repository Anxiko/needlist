defmodule Needlist.Python do
  @moduledoc """
  Interop with Python scripts
  """

  use GenServer

  alias Nullables.Result

  @spec scrape_listings(integer()) :: Result.result(String.t())
  def scrape_listings(release_id) do
    GenServer.call(__MODULE__, {:scrape_listings, release_id})
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    case start_python() do
      {:ok, pid} ->
        {:ok, pid}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def terminate(_reason, pid) do
    :python.stop(pid)
  end

  @impl true
  def handle_call({:scrape_listings, release_id}, _from, pid) do
    pid
    |> do_scrape_listings(release_id)
    |> case do
      {:reply, response} ->
        {:reply, response, pid}

      {:error, reason} ->
        {:stop, reason, {:error, reason}, pid}
    end
  end

  defp start_python do
    :python.start_link(python_path: String.to_charlist(python_path()))
  end

  @spec do_scrape_listings(pid(), integer()) :: {:reply, Result.result(String.t())} | {:error, any()}
  defp do_scrape_listings(pid, release_id) do
    pid
    |> :python.call(:discogs_scraper, :scrape_listings, [release_id])
    |> case do
      {~c"error", status_code} -> {:reply, {:error, {:status_code, status_code}}}
      {~c"ok", response} -> {:reply, {:ok, to_string(response)}}
    end
  rescue
    e in ErlangError ->
      :python.stop(pid)
      {:error, {:python_call, e}}
  end

  @spec python_path :: String.t()
  defp python_path do
    :needlist
    |> :code.priv_dir()
    |> Path.join("python")
  end
end

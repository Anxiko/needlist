defmodule NeedlistWeb.TasksController do
  @moduledoc """
  Controller used to trigger tasks through API requests.
  """

  use NeedlistWeb, :controller

  alias Needlist.Oban.Dispatcher

  @spec wantlist(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def wantlist(conn, _params) do
    result = Dispatcher.dispatch_wantlist_batch()
    respond_with_dispatch_result(conn, result)
  end

  @spec listings(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def listings(conn, _params) do
    result = Dispatcher.dispatch_listings_batch()
    respond_with_dispatch_result(conn, result)
  end

  defp respond_with_dispatch_result(conn, result) do
    case result do
      {:ok, %Oban.Job{} = job} ->
        conn
        |> put_status(:ok)
        |> json(serialize_oban_job(job))

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          error: "Failed to dispatch batch job",
          reason: inspect(reason)
        })
    end
  end

  defp serialize_oban_job(%Oban.Job{} = job) do
    %{
      id: job.id,
      state: job.state,
      queue: job.queue,
      worker: job.worker,
      args: job.args,
      inserted_at: job.inserted_at
    }
  end
end

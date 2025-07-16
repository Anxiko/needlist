defmodule Needlist.Repo.Job do
  @moduledoc """
  Core module for querying `Oban.Job` records.
  """

  import Ecto.Query

  alias Oban.Job

  @spec base_query :: Ecto.Query.t()
  def base_query do
    from(Job)
  end

  @spec by_state(query :: Ecto.Query.t(), state_or_states :: String.t() | [String.t()] | nil) :: Ecto.Query.t()
  def by_state(query, nil), do: query

  def by_state(query, state) when is_binary(state) do
    where(query, [j], j.state == ^state)
  end

  def by_state(query, states) when is_list(states) do
    where(query, [j], j.state in ^states)
  end

  @spec by_queue(query :: Ecto.Query.t(), queue :: String.t()) :: Ecto.Query.t()
  def by_queue(query, queue) do
    where(query, [j], j.queue == ^queue)
  end

  @spec ordered_by_completed_at(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def ordered_by_completed_at(query) do
    order_by(query, [j], desc_nulls_last: j.completed_at)
  end

  @spec by_username_arg(query :: Ecto.Query.t(), username :: String.t()) :: Ecto.Query.t()
  def by_username_arg(query, username) do
    where(query, [j], fragment("?->>'username'", j.args) == ^username)
  end

  @spec last_in_queue(queue :: String.t(), state_or_states :: String.t() | [String.t()] | nil) :: Ecto.Query.t()
  @spec last_in_queue(queue :: String.t()) :: Ecto.Query.t()
  def last_in_queue(queue, state_or_states \\ nil) do
    base_query()
    |> by_state(state_or_states)
    |> by_queue(queue)
    |> ordered_by_completed_at()
    |> first()
  end
end

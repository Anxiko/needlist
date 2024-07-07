defmodule NeedlistWeb.Navigation.PageEntry do
  @moduledoc """
  Entry in a pagination component, to perform relative (next, previous) or absolute jumps.
  """

  import Needlist.Guards, only: [is_pos_integer: 1]

  @keys [:page, :state]

  @enforce_keys @keys
  defstruct @keys

  @relations [:prev, :next]
  @states [:active, :current, :disabled]

  @type relation() :: :prev | :next
  @type page() :: pos_integer() | {relation(), pos_integer()}
  @type state() :: :active | :current | :disabled

  @type t() :: %__MODULE__{
          page: page(),
          state: state()
        }

  defguardp is_valid_state(state) when state in @states
  defguardp is_valid_relation(relation) when relation in @relations

  @spec absolute(pos_integer(), state()) :: t()
  @spec absolute(pos_integer()) :: t()
  def absolute(page, state \\ :active)

  def absolute(page, state) when is_pos_integer(page) and is_valid_state(state) do
    %__MODULE__{page: page, state: state}
  end

  @spec relative(relation(), pos_integer(), state()) :: t()
  @spec relative(relation(), pos_integer()) :: t()
  def relative(relation, current, state \\ :active)

  def relative(relation, current, state)
      when is_valid_relation(relation) and is_pos_integer(current) and is_valid_state(state) do
    %__MODULE__{page: {relation, current}, state: state}
  end

  @spec page(t()) :: pos_integer()
  def page(%__MODULE__{page: page}) do
    case page do
      {:prev, page} -> page - 1
      {:next, page} -> page + 1
      page when is_pos_integer(page) -> page
    end
  end
end

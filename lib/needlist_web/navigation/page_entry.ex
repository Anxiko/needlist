defmodule NeedlistWeb.Navigation.PageEntry do
  import Needlist.Guards, only: [is_pos_integer: 1]

  @keys [:page, :state]

  @enforce_keys @keys
  defstruct @keys

  @symbols [:prev, :next]
  @states [:active, :current, :disabled]

  @type page() :: pos_integer() | :prev | :next
  @type state() :: :active | :current | :disabled

  @type t() :: %__MODULE__{
          page: page(),
          state: state()
        }

  defguardp is_valid_page(page) when is_pos_integer(page) or page in @symbols
  defguardp is_valid_state(state) when state in @states

  @spec new(page()) :: t()
  @spec new(page(), state()) :: t()
  def new(page, state \\ :active)

  def new(page, state) when is_valid_page(page) and is_valid_state(state) do
    %__MODULE__{page: page, state: state}
  end
end

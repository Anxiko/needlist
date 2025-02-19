defmodule NeedlistWeb.Needlist.StateTest do
  use ExUnit.Case

  alias Needlist.Types.QueryOptions.SortKey
  alias Needlist.Types.QueryOptions.SortOrder
  alias NeedlistWeb.NeedlistLive.State

  describe "parsing a state from params" do
    test "produces the correct result for a valid state" do
      actual =
        "page=2&per_page=25&sort_key=artist&sort_order=desc"
        |> URI.decode_query()
        |> State.parse()

      expected = %State{
        page: 2,
        max_pages: nil,
        per_page: 25,
        sort_key: SortKey.artist(),
        sort_order: SortOrder.desc()
      }

      assert actual == expected
    end

    test "handles an invalid state gracefully" do
      # all of these are invalid!
      actual =
        "page=-10&per_page=many&sort_key=fake_key&sort_order=random"
        |> URI.decode_query()
        |> State.parse()

      expected = %State{}

      assert actual == expected
    end
  end
end

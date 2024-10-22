defmodule NeedlistWeb.Needlist.StateTest do
  use ExUnit.Case

  alias NeedlistWeb.NeedlistLive.State
  alias Needlist.Discogs.Api.Types

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
        sort_key: Types.SortKey.artist(),
        sort_order: Types.SortOrder.desc()
      }

      assert actual == expected
    end

    test "handles an invalid state gracefully" do

      actual =
        # all of these are invalid!
        "page=-10&per_page=many&sort_key=fake_key&sort_order=random"
        |> URI.decode_query()
        |> State.parse()

      expected = %State{}

      assert actual == expected
    end
  end
end

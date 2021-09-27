defmodule GridHero.GridMapTest do
  use ExUnit.Case, async: true

  alias GridHero.GridMap

  describe "valid_move?/2" do
    test "only walkable tiles are valid moves" do
      map = GridMap.generate()

      assert Enum.at(map.tiles, 0) == 0
      assert map.lookup[0] == 0
      refute GridMap.valid_move?(map, {0, 0})

      assert Enum.at(map.tiles, 11) == 1
      assert map.lookup[11] == 1
      assert GridMap.valid_move?(map, {1, 1})
    end

    test "out of bounds is not a valid move" do
      map = GridMap.generate()

      refute GridMap.valid_move?(map, {-1, -1})
      refute GridMap.valid_move?(map, {map.width + 1, map.height + 1})
    end
  end

  describe "get_spawn_position/1" do
    test "the returned position is a walkable tile" do
      map = GridMap.generate()

      # Since the position is randomized, test more than once.
      for _ <- 0..100 do
        assert GridMap.valid_move?(map, GridMap.get_spawn_position(map))
      end
    end
  end
end

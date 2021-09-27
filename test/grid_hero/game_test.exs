defmodule GridHero.GameTest do
  use ExUnit.Case, async: true

  import GridHero.GameList.Entry

  alias GridHero.GameList
  alias GridHero.Game

  setup context do
    _ = start_supervised!({GameList, name: context.test})
    game = GameList.create_game(context.test, Atom.to_string(context.test))

    %{game_list: context.test, game: game}
  end

  test "when a player joins, the gamelist's player count is updated", context do
    %{game_list: list, game: entry(id: id, pid: pid)} = context

    {:ok, entry(player_count: count)} = GameList.get_game(list, id)
    assert count == 0

    Game.connect_player(pid, "Player 1")

    {:ok, entry(player_count: count)} = GameList.get_game(list, id)
    assert count == 1
  end
end

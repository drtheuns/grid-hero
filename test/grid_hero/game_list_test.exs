defmodule GridHero.GameListTest do
  use ExUnit.Case, async: true

  alias GridHero.GameList
  import GridHero.GameList.Entry

  setup context do
    _ = start_supervised!({GameList, name: context.test})

    %{server: context.test}
  end

  test "create game and get all", %{server: server} do
    assert GameList.all(server) |> Enum.count() == 0

    entry = GameList.create_game(server, "My lobby")

    assert entry(entry, :name) == "My lobby"
    assert entry(entry, :player_count) == 0

    assert GameList.all(server) |> Enum.count() == 1
  end

  test "fetch game", %{server: server} do
    entry(id: id) = game = GameList.create_game(server, "My lobby")

    assert {:ok, ^game} = GameList.get_game(server, id)
  end

  test "increment player count", %{server: server} do
    entry(id: id, player_count: count) = GameList.create_game(server, "My lobby")

    assert count == 0
    assert GameList.increment_player_count(server, id) == 1
  end

  test "decrement player count", %{server: server} do
    entry(id: id, player_count: count) = GameList.create_game(server, "My lobby")

    assert count == 0
    assert GameList.increment_player_count(server, id) == 1
    assert GameList.decrement_player_count(server, id) == 0
  end

  test "it cannot decrement past zero", %{server: server} do
    entry(id: id, player_count: count) = GameList.create_game(server, "My lobby")

    assert count == 0
    assert GameList.decrement_player_count(server, id) == 0
  end
end

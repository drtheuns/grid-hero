defmodule GridHero.PlayerTest do
  use ExUnit.Case, async: true

  import GridHero.GameList.Entry

  alias GridHero.Game
  alias GridHero.GameList
  alias GridHero.Player

  setup context do
    _ = start_supervised!({GameList, name: context.test})
    entry(id: game_id, pid: game_pid) = GameList.create_game("Test game")
    {:ok, player_pid} = Game.connect_player(game_pid, "Player 1")

    %{game_list: context.test, game: game_pid, player: player_pid, game_id: game_id}
  end

  test "attacking a player", %{player: player1} do
    state = Player.get_state(player1)

    # Simulate attack. Doesn't use Game.attack because the message would
    # arrive after we call get_state.
    assert {:noreply, %{alive: false}} =
             Player.handle_cast({:enemy_attack, state.position}, state)
  end

  test "missing an attack", %{player: player1} do
    %{position: {x, y}} = state = Player.get_state(player1)

    assert {:noreply, %{alive: true}} = Player.handle_cast({:enemy_attack, {x + 2, y}}, state)
  end

  test "attacking a player has no effect the second time", %{player: player} do
    # There was briefly a bug where I didn't check the current alive status
    # when getting attacked. As a result, a miss would suddenly revive the player.
    state = Player.get_state(player)

    Player.enemy_attack(player, state.position)
    state = Player.get_state(player)

    refute state.alive

    Player.enemy_attack(player, state.position)
    state = Player.get_state(player)

    refute state.alive
  end
end

defmodule GridHero.GameList.Entry do
  @moduledoc """
  The representation of a single game entry in the game list.
  """
  import Record

  @doc """
  A single game list record.
  """
  defrecord(:entry, id: nil, pid: nil, name: "", player_count: 0)

  @type t ::
          record(:entry,
            id: GridHero.GameList.game_id(),
            pid: pid(),
            name: String.t(),
            player_count: non_neg_integer()
          )

  def to_map({:entry, id, pid, name, player_count}) do
    %{id: id, pid: pid, name: name, player_count: player_count}
  end
end

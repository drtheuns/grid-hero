defmodule GridHero.GridMap do
  @moduledoc """
  The tile-based map that each game uses.

  Every tile is a simple integer. `0` is unwalkable while `1` _is_ walkable.
  """
  defstruct [:width, :height, :tiles, :lookup]

  @type tile_inaccessible :: 0
  @type tile_accessible :: 1
  @type position :: {non_neg_integer(), non_neg_integer()}

  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          tiles: list(tile_inaccessible() | tile_accessible()),
          lookup: map()
        }

  # Used to work around the formatter.
  @default_map Code.eval_string("""
               [
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                 0, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                 0, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                 0, 0, 1, 0, 0, 0, 0, 1, 1, 0,
                 0, 1, 1, 1, 0, 1, 1, 1, 1, 0,
                 0, 1, 1, 1, 0, 1, 1, 1, 1, 0,
                 0, 1, 1, 1, 0, 1, 1, 1, 1, 0,
                 0, 1, 1, 1, 1, 1, 1, 1, 1, 0,
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               ]
               """)
               |> elem(0)

  def generate() do
    lookup =
      @default_map
      |> Enum.with_index()
      |> Enum.map(fn {val, pos} -> {pos, val} end)
      |> Enum.into(%{})

    # No time for a map generator. Using the map provided in the assignment.
    %__MODULE__{
      width: 10,
      height: 10,
      lookup: lookup,
      tiles: @default_map
    }
  end

  @doc """
  Validate that the given position is valid within the map.

  The position must be within bounds and also on a walkable tile.
  """
  @spec valid_move?(t(), position :: {x :: integer(), y :: integer()}) :: boolean
  def valid_move?(map, {x, y}) do
    if x < 0 or y < 0 or x > map.width - 1 or y > map.height - 1 do
      false
    else
      Map.get(map.lookup, coordinates_to_index(map, x, y), 0) == 1
    end
  end

  @doc """
  Generate a random spawn position.
  """
  @spec get_spawn_position(t()) :: {non_neg_integer, non_neg_integer}
  def get_spawn_position(map) do
    max_index = map.width * map.height - 1
    index = :rand.uniform(max_index)
    step = if index <= max_index / 2, do: 1, else: -1

    # Using a random index within the map tiles, move forward/backward until
    # we reach a walkable tile.
    get_spawn_position(map, index, max_index, step)
  end

  # If we reach the end of the map, try again with different position.
  defp get_spawn_position(map, 0, max, -1), do: get_spawn_position(map, max, max, -1)
  defp get_spawn_position(map, max, max, 1), do: get_spawn_position(map, 0, max, 1)

  defp get_spawn_position(map, index, max, step) do
    if Map.get(map.lookup, index, 0) == 0 do
      get_spawn_position(map, index + step, max, step)
    else
      index_to_coordinates(map, index)
    end
  end

  defp index_to_coordinates(map, index) do
    {rem(index, map.width), div(index, map.width)}
  end

  defp coordinates_to_index(map, x, y), do: y * map.width + x
end

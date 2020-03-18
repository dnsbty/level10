defmodule Level10.Games.Levels do
  @moduledoc """
  The game typically goes through 10 levels. This module contains the details
  for those levels so that they can be grabbed when needed.
  """

  @levels %{
    1 => [set: 3, set: 3],
    2 => [set: 3, run: 4],
    3 => [set: 4, run: 4],
    4 => [run: 7],
    5 => [run: 8],
    6 => [run: 9],
    7 => [set: 4, set: 4],
    8 => [color: 7],
    9 => [set: 5, set: 2],
    10 => [set: 5, set: 3]
  }

  @spec by_number(integer()) :: Keyword.t()
  def by_number(level_number) do
    Map.get(@levels, level_number)
  end
end

defmodule Level10.Games.Player do
  @moduledoc """
  Represents a player within a game. Each player will have a randomly generated
  ID and their name. Eventually these may be stored in a database for
  persistent record keeping and other things.
  """

  defstruct [:id, :name]

  def new(name) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      name: name
    }
  end
end

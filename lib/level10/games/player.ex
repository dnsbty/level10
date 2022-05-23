defmodule Level10.Games.Player do
  @moduledoc """
  Represents a player within a game.
  """

  @type t :: %__MODULE__{id: String.t(), name: String.t()}

  @derive Jason.Encoder
  defstruct [:id, :name]

  @doc """
  Takes in a user struct from the user's session and returns a player struct
  with just the information needed for playing a game.
  """
  @spec new(User.t()) :: __MODULE__.t()
  def new(user) do
    %__MODULE__{
      id: user.id,
      name: user.name
    }
  end
end

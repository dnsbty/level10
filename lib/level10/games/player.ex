defmodule Level10.Games.Player do
  @moduledoc """
  Represents a player within a game.
  """

  @type id :: String.t()
  @type t :: %__MODULE__{id: id(), name: String.t()}

  @derive {Jason.Encoder, only: [:id, :name]}
  defstruct [:id, :name]
end

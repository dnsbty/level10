defmodule Level10.Games.Player do
  @moduledoc """
  Represents a player within a game.
  """

  @type t :: %__MODULE__{device_token: String.t() | nil, id: String.t(), name: String.t()}

  @derive {Jason.Encoder, only: [:id, :name]}
  defstruct [:device_token, :id, :name]
end

defmodule Level10.Games.Settings do
  @moduledoc """
  The game's settings allow for different variations to be played.
  """

  @type setting :: atom()
  @type t :: %__MODULE__{
          skip_next_player: boolean()
        }

  defstruct ~W[
    skip_next_player
  ]a

  @doc """
  Returns the default settings.
  """
  @spec default :: t()
  def default do
    %__MODULE__{
      skip_next_player: false
    }
  end

  @doc """
  Sets the specified setting to the value provided.
  """
  @spec set(t(), setting(), boolean()) :: t()
  def set(settings, name, value) do
    Map.put(settings, name, value)
  end
end

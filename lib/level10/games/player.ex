defmodule Level10.Games.Player do
  defstruct [:key, :name]

  def new(name) do
    %__MODULE__{
      key: Ecto.UUID.generate(),
      name: name
    }
  end
end

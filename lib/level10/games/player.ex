defmodule Level10.Games.Player do
  defstruct [:id, :name]

  def new(name) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      name: name
    }
  end
end

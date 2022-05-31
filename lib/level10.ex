defmodule Level10 do
  @moduledoc """
  Level10 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defimpl Jason.Encoder, for: [MapSet, Range, Stream] do
    def encode(struct, opts) do
      Jason.Encode.list(Enum.to_list(struct), opts)
    end
  end
end

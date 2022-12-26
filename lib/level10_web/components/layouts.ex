defmodule Level10Web.Layouts do
  @moduledoc false

  use Level10Web, :html

  embed_templates "layouts/*"

  @spec hide_overflow(String.t(), map) :: String.t()
  def hide_overflow(class, %{overflow_hidden: true}), do: class <> " overflow-hidden"
  def hide_overflow(class, _), do: class
end

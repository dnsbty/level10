defmodule Level10Web.LayoutView do
  use Level10Web, :view

  @spec hide_overflow(String.t(), map) :: String.t()
  def hide_overflow(class, %{overflow_hidden: true}), do: class <> " overflow-hidden"
  def hide_overflow(class, _), do: class
end

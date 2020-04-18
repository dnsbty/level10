defmodule Level10Web.GameView do
  use Level10Web, :view

  def background_class(:blue), do: "bg-blue-600"
  def background_class(:green), do: "bg-green-600"
  def background_class(:red), do: "bg-red-600"
  def background_class(:yellow), do: "bg-yellow-600"

  def number(:one), do: "1"
  def number(:two), do: "2"
  def number(:three), do: "3"
  def number(:four), do: "4"
  def number(:five), do: "5"
  def number(:six), do: "6"
  def number(:seven), do: "7"
  def number(:eight), do: "8"
  def number(:nine), do: "9"
  def number(:ten), do: "10"
  def number(:eleven), do: "11"
  def number(:twelve), do: "12"
  def number(:skip), do: "S"
  def number(:wild), do: "W"
end

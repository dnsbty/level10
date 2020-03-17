defmodule Level10.Games.CardTest do
  use ExUnit.Case, async: true
  alias Level10.Games.Card

  describe "new/2" do
    test "creates a card with value and color" do
      card = Card.new(:seven, :blue)

      assert card.color == :blue
      assert card.value == :seven
    end
  end

  describe "score/1" do
    test "single digit cards score 5 points" do
      one = Card.new(:one, :blue)
      two = Card.new(:two, :green)
      three = Card.new(:three, :red)
      four = Card.new(:four, :yellow)
      five = Card.new(:five, :blue)
      six = Card.new(:six, :green)
      seven = Card.new(:seven, :red)
      eight = Card.new(:eight, :yellow)
      nine = Card.new(:nine, :blue)

      assert Card.score(one) == 5
      assert Card.score(two) == 5
      assert Card.score(three) == 5
      assert Card.score(four) == 5
      assert Card.score(five) == 5
      assert Card.score(six) == 5
      assert Card.score(seven) == 5
      assert Card.score(eight) == 5
      assert Card.score(nine) == 5
    end

    test "double digit cards score 10 points" do
      ten = Card.new(:ten, :green)
      eleven = Card.new(:eleven, :red)
      twelve = Card.new(:twelve, :yellow)

      assert Card.score(ten) == 10
      assert Card.score(eleven) == 10
      assert Card.score(twelve) == 10
    end

    test "skips score 15 points" do
      skip = Card.new(:skip, :blue)

      assert Card.score(skip) == 15
    end

    test "wilds score 25 points" do
      wild = Card.new(:wild, :green)

      assert Card.score(wild) == 25
    end
  end
end

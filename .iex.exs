alias Level10.Games
alias Games.{Card, Game, Levels, Player}

{:ok, game, player1} = Games.create_game("Player 1")
{:ok, player2} = Games.join_game(game, "Player 2")
{:ok, player3} = Games.join_game(game, "Player 3")

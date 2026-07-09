class GoFishGame < Game
  serialize :game_state, coder: GoFish::Game

  def create_and_start_game
    new_game = GoFish::Game.new(users.map { |u| GoFish::Player.new(u.id) })
    new_game.deal!
    new_game
  end
end

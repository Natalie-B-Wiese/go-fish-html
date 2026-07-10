class GoFishGame < Game
  serialize :game_state, coder: GoFish::Implementation

  def presenter_class
    GoFishGamePresenter
  end

  def create_and_start_game
    new_game = GoFish::Implementation.new(users.map { |u| GoFish::Player.new(u.id) })
    new_game.deal!
    new_game
  end
end

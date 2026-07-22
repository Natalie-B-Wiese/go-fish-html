class RummyGame < Game
  serialize :game_state, coder: Rummy::Implementation

  def presenter_class
    RummyGamePresenter
  end

  def create_and_start_game
    new_game = Rummy::Implementation.new(users.map { |u| Rummy::Player.new(u.id) })
    new_game.start!
    new_game
  end
end

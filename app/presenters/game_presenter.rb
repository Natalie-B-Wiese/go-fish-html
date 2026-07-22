class GamePresenter
  attr_reader :game, :my_user

  def initialize(game, my_user)
    @game = game
    @my_user = my_user
  end

  def opponent_users
    game.users - [my_user]
  end

  def user_names_by_id
    game.users.to_h { |user| [user.id, user.name] }
  end

  def implementation
    game.game_state
  end

  def implementation?
    !implementation.nil?
  end

  # all methods below this only work if game is started (aka full)
  def my_implementation_player
    implementation_players_hash[my_user.id]
  end

  # the user whose turn it currently is
  def implementation_current_user
    game.users.find(implementation.current_user_id)
  end

  # def implementation_players_hash
  delegate :players_hash, to: :implementation, prefix: true

  def my_turn?
    implementation.current_user_id == my_user.id
  end
end

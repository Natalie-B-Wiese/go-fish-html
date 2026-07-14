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

  def play_turn?(player: nil, rank: nil)
    if player.nil? && rank.nil?
      !!game_state.draw_deck_turn
    else
      # rank: nil, suit: nil

      return false if player.nil? || rank.nil?

      request_opponent_turn?(opponent_user_id_s: player, rank: rank)
    end
  end

  private

  def request_opponent_turn?(opponent_user_id_s:, rank:)
    opponent_user_id = Integer(opponent_user_id_s, exception: false)
    return false if opponent_user_id.nil?

    !!game_state.request_opponent_turn(opponent_user_id: opponent_user_id, rank_requested: rank)
  end
end

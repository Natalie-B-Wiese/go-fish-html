class CrazyEightsGame < Game
  serialize :game_state, coder: CrazyEights::Implementation

  def presenter_class
    CrazyEightsGamePresenter
  end

  def create_and_start_game
    new_game = CrazyEights::Implementation.new(users.map { |u| CrazyEights::Player.new(u.id) })
    new_game.start!
    new_game
  end

  # note, the card passed in is actually a card key
  def play_turn?(card: nil)
    if card.nil?
      !!game_state.draw_deck_turn
    else
      # return false if conversion from card key to card failed
      # return false if player.nil? || rank.nil?
      card_obj = Card.from_key(card)
      !!game_state.play_turn(rank: card_obj.rank, suit: card_obj.suit)
    end
  end
end

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

  def play_turn?(source: 'deck', card: nil, **)
    return !!discard_turn(card) if card

    source == 'discard' ? !!game_state.draw_discard_turn : !!game_state.draw_deck_turn
  end

  private

  def discard_turn(card_key)
    card = Card.from_key(card_key)
    game_state.discard_turn(rank: card.rank, suit: card.suit)
  end
end

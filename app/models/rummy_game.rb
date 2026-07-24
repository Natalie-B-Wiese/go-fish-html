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

  def play_turn?(source: 'deck', card: nil, cards: nil, meld: nil, **)
    return !!cards_turn(meld, cards) if cards
    return !!discard_turn(card) if card

    !!draw_turn(source)
  end

  private

  def draw_turn(source)
    source == 'discard' ? game_state.draw_discard_turn : game_state.draw_deck_turn
  end

  # a card selection either extends the meld chosen in the dropdown or lays a new one
  def cards_turn(meld_index, card_keys)
    return lay_off_turn(meld_index, card_keys) if meld_index.present?

    meld_turn(card_keys)
  end

  def discard_turn(card_key)
    card = Card.from_key(card_key)
    game_state.discard_turn(rank: card.rank, suit: card.suit)
  end

  def meld_turn(card_keys)
    game_state.meld_turn(cards: to_cards(card_keys))
  end

  def lay_off_turn(meld_index, card_keys)
    index = Integer(meld_index, exception: false)
    return nil unless index

    game_state.lay_off_turn(meld_index: index, cards: to_cards(card_keys))
  end

  def to_cards(card_keys)
    card_keys.map { |key| Card.from_key(key) }
  end
end

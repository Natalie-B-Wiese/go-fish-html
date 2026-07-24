class RummyGamePresenter < GamePresenter
  def can_draw?
    my_turn? && !implementation.drawn?
  end

  def discard_card
    implementation.discard_pile.top_card
  end

  def can_take_discard?
    can_draw? && !implementation.discard_pile.empty?
  end

  def can_discard?
    my_turn? && implementation.drawn?
  end

  def can_meld?
    my_turn? && implementation.drawn?
  end

  def melds
    implementation.melds
  end

  def hand_cards_h
    CardCollection.cards_to_h(my_implementation_player.cards)
  end

  def discardable_cards_h
    CardCollection.cards_to_h(implementation.discardable_cards)
  end
end

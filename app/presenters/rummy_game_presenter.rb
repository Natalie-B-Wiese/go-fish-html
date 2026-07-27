class RummyGamePresenter < GamePresenter
  NEW_MELD_LABEL = 'New Meld'.freeze
  NEW_MELD_OPTION = { NEW_MELD_LABEL => '' }.freeze

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

  def meld_options_h
    return NEW_MELD_OPTION unless can_lay_off?

    NEW_MELD_OPTION.merge(melds.each_with_index.to_h { |meld, index| ["Meld #{index + 1}: #{meld}", index] })
  end

  def can_lay_off?
    can_meld? && my_implementation_player.melded?
  end

  def hand_cards_h
    CardCollection.cards_to_h(my_implementation_player.cards)
  end

  def discardable_cards_h
    CardCollection.cards_to_h(implementation.discardable_cards)
  end
end

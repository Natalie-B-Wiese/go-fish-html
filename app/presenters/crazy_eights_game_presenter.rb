class CrazyEightsGamePresenter < GamePresenter
  # add helper methods here
  def playable_cards_h
    my_implementation_player.cards_to_h(my_implementation_player.playable_cards(discard_card))
  end

  def discard_card
    implementation.discard_pile.top_card
  end
end
